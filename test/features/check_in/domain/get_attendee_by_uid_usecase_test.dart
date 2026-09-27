import 'package:event_scan/core/error/failures.dart';
import 'package:event_scan/core/error/result.dart';
import 'package:event_scan/features/check_in/domain/entities/attendee.dart';
import 'package:event_scan/features/check_in/domain/repositories/check_in_repository.dart';
import 'package:event_scan/features/check_in/domain/usecases/get_attendee_by_uid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCheckInRepository extends Mock implements CheckInRepository {}

void main() {
  late _MockCheckInRepository repository;
  late GetAttendeeByUidUseCase useCase;

  const attendee = Attendee(
    rut: '1-9',
    nombre: 'Ana',
    apellido: 'Diaz',
    email: 'ana@test.com',
    telefono: '+56911111111',
    distrito: 'Centro',
    iglesia: 'Luz',
    tallerAm: 'Oracion',
    tallerPm: 'Servicio',
  );

  setUp(() {
    repository = _MockCheckInRepository();
    useCase = GetAttendeeByUidUseCase(repository);
  });

  test('returns validation failure for invalid UID', () async {
    final result = await useCase('invalid');

    expect(result, isA<Error<Attendee>>());
    expect((result as Error<Attendee>).failure, isA<ValidationFailure>());
    verifyNever(() => repository.getAttendeeByUid(any()));
  });

  test('returns attendee when repository succeeds', () async {
    const uid = '550e8400-e29b-41d4-a716-446655440000';
    when(() => repository.getAttendeeByUid(uid)).thenAnswer(
      (_) async => const Success<Attendee>(attendee),
    );

    final result = await useCase(uid);

    expect(result, isA<Success<Attendee>>());
    final success = result as Success<Attendee>;
    expect(success.value, attendee);
    verify(() => repository.getAttendeeByUid(uid)).called(1);
  });

  test('accepts RUT and queries repository', () async {
    const rut = '10467097-0';
    when(() => repository.getAttendeeByUid(rut)).thenAnswer(
      (_) async => const Success<Attendee>(attendee),
    );

    final result = await useCase(rut);

    expect(result, isA<Success<Attendee>>());
    verify(() => repository.getAttendeeByUid(rut)).called(1);
  });

  test('normalizes dotted RUT before querying repository', () async {
    const typedRut = '10.467.097-k';
    const normalizedRut = '10467097-K';

    when(() => repository.getAttendeeByUid(normalizedRut)).thenAnswer(
      (_) async => const Success<Attendee>(attendee),
    );

    final result = await useCase(typedRut);

    expect(result, isA<Success<Attendee>>());
    verify(() => repository.getAttendeeByUid(normalizedRut)).called(1);
  });
}
