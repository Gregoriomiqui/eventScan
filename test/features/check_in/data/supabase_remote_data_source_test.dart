import 'package:event_scan/core/error/exceptions.dart';
import 'package:event_scan/core/network/api_config.dart';
import 'package:event_scan/core/network/app_supabase_client.dart';
import 'package:event_scan/features/check_in/data/datasources/supabase_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppSupabaseClient extends Mock implements AppSupabaseClient {}

void main() {
  late _MockAppSupabaseClient client;
  late SupabaseRemoteDataSourceImpl dataSource;

  const config = ApiConfig(
    supabaseUrl: 'https://example.supabase.co',
    supabaseAnonKey: 'anon-key',
    attendeesTable: 'registered',
    enrollmentCodeColumn: 'CODIGO_INSCRIPCION',
  );

  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
    registerFallbackValue(const Duration(seconds: 1));
  });

  setUp(() {
    client = _MockAppSupabaseClient();
    dataSource = SupabaseRemoteDataSourceImpl(client: client, apiConfig: config);
  });

  test('returns attendee model when supabase query succeeds', () async {
    const payload = {
      'rut': '1-9',
      'nombre': 'Ana',
      'apellido': 'Diaz',
      'email': 'ana@test.com',
      'telefono': '+56911111111',
      'distrito': 'Centro',
      'iglesia': 'Luz',
      'taller_am': 'Oracion',
      'taller_pm': 'Servicio',
    };

    when(
      () => client.findAttendeeByUid(
        table: any(named: 'table'),
        enrollmentCodeColumn: any(named: 'enrollmentCodeColumn'),
        rutColumn: any(named: 'rutColumn'),
        uid: any(named: 'uid'),
        timeout: any(named: 'timeout'),
      ),
    ).thenAnswer((_) async => payload);

    final result = await dataSource.getAttendeeByUid('550e8400-e29b-41d4-a716-446655440000');

    expect(result.nombre, 'Ana');
  });

  test('propagates not found exception', () async {
    when(
      () => client.findAttendeeByUid(
        table: any(named: 'table'),
        enrollmentCodeColumn: any(named: 'enrollmentCodeColumn'),
        rutColumn: any(named: 'rutColumn'),
        uid: any(named: 'uid'),
        timeout: any(named: 'timeout'),
      ),
    ).thenThrow(const NotFoundException('Asistente no registrado'));

    expect(
      () => dataSource.getAttendeeByUid('550e8400-e29b-41d4-a716-446655440000'),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('propagates server exception', () async {
    when(
      () => client.findAttendeeByUid(
        table: any(named: 'table'),
        enrollmentCodeColumn: any(named: 'enrollmentCodeColumn'),
        rutColumn: any(named: 'rutColumn'),
        uid: any(named: 'uid'),
        timeout: any(named: 'timeout'),
      ),
    ).thenThrow(const ServerException('Error 500'));

    expect(
      () => dataSource.getAttendeeByUid('550e8400-e29b-41d4-a716-446655440000'),
      throwsA(isA<ServerException>()),
    );
  });

  test('propagates network exception', () async {
    when(
      () => client.findAttendeeByUid(
        table: any(named: 'table'),
        enrollmentCodeColumn: any(named: 'enrollmentCodeColumn'),
        rutColumn: any(named: 'rutColumn'),
        uid: any(named: 'uid'),
        timeout: any(named: 'timeout'),
      ),
    ).thenThrow(const NetworkException('Timeout'));

    expect(
      () => dataSource.getAttendeeByUid('550e8400-e29b-41d4-a716-446655440000'),
      throwsA(isA<NetworkException>()),
    );
  });
}
