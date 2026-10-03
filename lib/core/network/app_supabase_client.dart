import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:event_scan/core/error/exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';

abstract class AppSupabaseClient {
  Future<List<Map<String, dynamic>>> fetchAllRows({
    required String table,
    required Duration timeout,
  });

  Future<Map<String, dynamic>> findAttendeeByUid({
    required String table,
    required String enrollmentCodeColumn,
    required String rutColumn,
    required String uid,
    required Duration timeout,
  });

  Future<void> markCheckIn({
    required String table,
    required String enrollmentCodeColumn,
    required String rutColumn,
    required String uid,
    required DateTime checkedInAt,
    required Duration timeout,
  });
}

class SupabaseAppClient implements AppSupabaseClient {
  SupabaseAppClient(this._client);

  final SupabaseClient _client;
  static const JsonEncoder _prettyJson = JsonEncoder.withIndent('  ');

  String _normalizeForCompare(String value) {
    return value
        .trim()
        .replaceAll('.', '')
        .replaceAll(' ', '')
        .toUpperCase();
  }

  bool _looksLikeRut(String value) {
    return RegExp(r'^\d{7,8}-[0-9Kk]$').hasMatch(value.trim());
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllRows({
    required String table,
    required Duration timeout,
  }) async {
    try {
      const pageSize = 1000;
      var from = 0;
      final rows = <Map<String, dynamic>>[];

      while (true) {
        final response = await _client
            .from(table)
            .select('*')
            .range(from, from + pageSize - 1)
            .timeout(timeout);

        final batch = (response as List)
            .map((entry) => Map<String, dynamic>.from(entry as Map))
            .toList();

        rows.addAll(batch);

        if (batch.length < pageSize) {
          break;
        }

        from += pageSize;
      }

      return rows;
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado');
    } on SocketException {
      throw const NetworkException('Error de red');
    } on PostgrestException catch (exception) {
      throw _mapPostgrestException(exception);
    }
  }

  ServerException _mapPostgrestException(PostgrestException exception) {
    final message = exception.message;
    final code = exception.code ?? '';

    final isPermissionDenied =
        code == '42501' || message.contains('"code":"42501"');
    if (isPermissionDenied) {
      return const ServerException(
        'Sin permisos en Supabase para leer/actualizar la tabla. Revisa GRANT y politicas RLS para el rol anon.',
      );
    }

    final isMissingColumn =
        code == '42703' || message.contains('"code":"42703"');
    if (isMissingColumn) {
      return const ServerException(
        'La tabla no tiene una de las columnas esperadas. Revisa el esquema en Supabase.',
      );
    }

    return ServerException(message);
  }

  @override
  Future<Map<String, dynamic>> findAttendeeByUid({
    required String table,
    required String enrollmentCodeColumn,
    required String rutColumn,
    required String uid,
    required Duration timeout,
  }) async {
    try {
      final normalizedUid = _normalizeForCompare(uid);

      final response = await _client
          .from(table)
          .select('*')
          .or('$enrollmentCodeColumn.eq.$uid,$rutColumn.eq.$uid')
          .maybeSingle()
          .timeout(timeout);

      if (response == null && _looksLikeRut(uid)) {
        final candidates = await _client
            .from(table)
            .select('*')
            .ilike(rutColumn, '%$uid%')
            .limit(25)
            .timeout(timeout);

        final matched = candidates
            .cast<Map<String, dynamic>>()
            .firstWhere(
              (row) {
                final rawRut = (row[rutColumn] ?? '').toString();
                return _normalizeForCompare(rawRut) == normalizedUid;
              },
              orElse: () => <String, dynamic>{},
            );

        if (matched.isNotEmpty) {
          debugPrint(
            '[Supabase] findAttendeeByUid fallback response:\n${_prettyJson.convert(matched)}',
          );
          return matched;
        }
      }

      if (response == null) {
        throw const NotFoundException('Asistente no registrado');
      }

      final mapped = Map<String, dynamic>.from(response);
      debugPrint(
        '[Supabase] findAttendeeByUid response:\n${_prettyJson.convert(mapped)}',
      );

      return mapped;
    } on NotFoundException {
      rethrow;
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado');
    } on SocketException {
      throw const NetworkException('Error de red');
    } on PostgrestException catch (exception) {
      throw _mapPostgrestException(exception);
    }
  }

  @override
  Future<void> markCheckIn({
    required String table,
    required String enrollmentCodeColumn,
    required String rutColumn,
    required String uid,
    required DateTime checkedInAt,
    required Duration timeout,
  }) async {
    try {
      final attendee = await findAttendeeByUid(
        table: table,
        enrollmentCodeColumn: enrollmentCodeColumn,
        rutColumn: rutColumn,
        uid: uid,
        timeout: timeout,
      );

      final resolvedEnrollmentCode =
          (attendee[enrollmentCodeColumn] ?? '').toString().trim();
      if (resolvedEnrollmentCode.isEmpty) {
        throw const NotFoundException('Asistente no registrado');
      }

      final response = await _client
          .from(table)
          .update({'CHECK_IN': true})
          .eq(enrollmentCodeColumn, resolvedEnrollmentCode)
          .select(enrollmentCodeColumn)
          .maybeSingle()
          .timeout(timeout);

      if (response == null) {
        throw const NotFoundException('Asistente no registrado');
      }

      debugPrint(
        '[Supabase] markCheckIn response:\n${_prettyJson.convert(response)}',
      );
    } on NotFoundException {
      rethrow;
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado');
    } on SocketException {
      throw const NetworkException('Error de red');
    } on PostgrestException catch (exception) {
      throw _mapPostgrestException(exception);
    }
  }
}
