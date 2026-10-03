import 'dart:io';

import 'package:event_scan/core/network/app_supabase_client.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfOpenException implements Exception {
  const PdfOpenException(this.message);

  final String message;
}

class CheckInPdfExportService {
  static const int _minimumPdfPages = 50;
  static const int _pageSafetyMargin = 10;

  static const Set<String> _excludedColumns = {
    'ID_REGISTRO',
    'CODIGO_INSCRIPCION',
    'URL_CODIGO_QR',
    'ESTADO_PAGO',
    'CONTACTO_PRINCIPAL',
    'ID_TRANSACCION_BANCARIA',
    'FECHA_ACTUALIZACION',
    'FECHA_INSCRIPCION',
  };

  CheckInPdfExportService({
    required AppSupabaseClient client,
    required Duration timeout,
  }) : _client = client,
       _timeout = timeout;

  final AppSupabaseClient _client;
  final Duration _timeout;

  Future<void> exportTable({
    required String table,
    required String reportTitle,
    Set<String> additionalExcludedColumns = const {},
    void Function(String stage)? onStageChanged,
  }) async {
    onStageChanged?.call('Consultando datos del listado...');
    final rows = await _client.fetchAllRows(table: table, timeout: _timeout);

    onStageChanged?.call('Generando documento PDF...');
    final pdfBytes = await _buildPdf(
      reportTitle: reportTitle,
      table: table,
      rows: rows,
      additionalExcludedColumns: additionalExcludedColumns,
    );

    final safeTableName = table.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = '${safeTableName}_$timestamp.pdf';

    onStageChanged?.call('Guardando PDF en el dispositivo...');
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes, flush: true);

    onStageChanged?.call('Abriendo el PDF...');
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      if (result.type == ResultType.noAppToOpen) {
        throw PdfOpenException(
          'El PDF se guardo correctamente en ${file.path}, pero no hay una app lectora de PDF instalada para abrirlo.',
        );
      }

      throw PdfOpenException(
        'El PDF se guardo en ${file.path}, pero no se pudo abrir: ${result.message}',
      );
    }

    debugPrint('[PDF] Listado exportado y abierto: ${file.path}');
  }

  Future<Uint8List> _buildPdf({
    required String reportTitle,
    required String table,
    required List<Map<String, dynamic>> rows,
    Set<String> additionalExcludedColumns = const {},
  }) async {
    final doc = pw.Document();

    final columns = columnsForRows(
      rows,
      additionalExcludedColumns: additionalExcludedColumns,
    );
    final data = rows
        .map(
          (row) => columns
              .map((key) => _cellValue(row[key]))
              .toList(growable: false),
        )
        .toList(growable: false);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        maxPages: maxPagesForRowCount(rows.length),
        build: (context) => [
          pw.Text(
            reportTitle,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Tabla: $table'),
          pw.Text('Fecha: ${DateTime.now()}'),
          pw.Text('Total registros: ${rows.length}'),
          pw.SizedBox(height: 12),
          if (rows.isEmpty)
            pw.Text('No hay registros para exportar.')
          else
            pw.TableHelper.fromTextArray(
              headers: columns,
              data: data,
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
              cellAlignment: pw.Alignment.centerLeft,
            ),
        ],
      ),
    );

    return doc.save();
  }

  @visibleForTesting
  static int maxPagesForRowCount(int rowCount) {
    return (rowCount + _pageSafetyMargin).clamp(_minimumPdfPages, 0x7fffffff);
  }

  @visibleForTesting
  static List<String> columnsForRows(
    List<Map<String, dynamic>> rows, {
    Set<String> additionalExcludedColumns = const {},
  }) {
    if (rows.isEmpty) {
      return const <String>[];
    }

    final excludedColumns = {
      ..._excludedColumns,
      ...additionalExcludedColumns.map(_normalizeColumnName),
    };
    final ordered = <String>[];
    for (final row in rows) {
      for (final key in row.keys) {
        if (!excludedColumns.contains(_normalizeColumnName(key)) &&
            !ordered.contains(key)) {
          ordered.add(key);
        }
      }
    }
    return ordered;
  }

  static String _normalizeColumnName(String name) {
    return name
        .trim()
        .toUpperCase()
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O');
  }

  String _cellValue(Object? value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }
}
