import 'package:bloc_test/bloc_test.dart';
import 'package:event_scan/core/error/result.dart';
import 'package:event_scan/features/check_in/domain/entities/attendee.dart';
import 'package:event_scan/features/check_in/domain/repositories/check_in_repository.dart';
import 'package:event_scan/features/check_in/domain/usecases/confirm_check_in.dart';
import 'package:event_scan/features/check_in/domain/usecases/get_attendee_by_uid.dart';
import 'package:event_scan/features/check_in/presentation/state/check_in_bloc.dart';
import 'package:event_scan/features/check_in/presentation/state/check_in_event.dart';
import 'package:event_scan/features/check_in/presentation/state/check_in_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCheckInRepository extends Mock implements CheckInRepository {}

void main() {
  late _MockCheckInRepository repository;
  late CheckInBloc bloc;

  const validUid = '550e8400-e29b-41d4-a716-446655440000';

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

  const attendeePagoPendiente = Attendee(
    rut: '1-9',
    nombre: 'Ana',
    apellido: 'Diaz',
    email: 'ana@test.com',
    telefono: '+56911111111',
    distrito: 'Centro',
    iglesia: 'Luz',
    tallerAm: 'Oracion',
    tallerPm: 'Servicio',
    estadoPago: 'PENDIENTE',
  );

  setUp(() {
    repository = _MockCheckInRepository();
    bloc = CheckInBloc(
      getAttendeeByUid: GetAttendeeByUidUseCase(repository),
      confirmCheckIn: ConfirmCheckInUseCase(repository),
      now: () => DateTime(2026, 1, 1, 9),
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  blocTest<CheckInBloc, CheckInState>(
    'emits attendee when validate succeeds',
    build: () {
      when(() => repository.getAttendeeByUid(validUid)).thenAnswer(
        (_) async => const Success(attendee),
      );
      return bloc;
    },
    act: (bloc) {
      bloc
        ..add(const UidUpdated(validUid))
        ..add(const ValidateRequested());
    },
    expect: () => [
      const CheckInState(uid: validUid),
      const CheckInState(uid: validUid, isValidating: true),
      const CheckInState(
        uid: validUid,
        attendee: attendee,
        feedbackMessage: 'Registro encontrado. Listo para check-in.',
        feedbackType: FeedbackType.info,
        feedbackId: 1,
      ),
    ],
  );

  blocTest<CheckInBloc, CheckInState>(
    'resets uid and enables next scan after successful check-in',
    build: () {
      when(() => repository.getAttendeeByUid(validUid)).thenAnswer(
        (_) async => const Success(attendee),
      );
      when(
        () => repository.confirmCheckIn(
          uid: validUid,
          checkedInAt: DateTime(2026, 1, 1, 9),
        ),
      ).thenAnswer((_) async => const Success(null));
      return bloc;
    },
    act: (bloc) async {
      bloc
        ..add(const UidUpdated(validUid))
        ..add(const ValidateRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ConfirmCheckInRequested());
    },
    verify: (_) {
      expect(bloc.state.uid, isEmpty);
      expect(bloc.state.canScanNext, isTrue);
      expect(bloc.state.feedbackType, FeedbackType.success);
    },
  );

  blocTest<CheckInBloc, CheckInState>(
    'emits pending payment message when attendee has ESTADO_PAGO PENDIENTE',
    build: () {
      when(() => repository.getAttendeeByUid(validUid)).thenAnswer(
        (_) async => const Success(attendeePagoPendiente),
      );
      return bloc;
    },
    act: (bloc) {
      bloc
        ..add(const UidUpdated(validUid))
        ..add(const ValidateRequested());
    },
    expect: () => [
      const CheckInState(uid: validUid),
      const CheckInState(uid: validUid, isValidating: true),
      const CheckInState(
        uid: validUid,
        attendee: attendeePagoPendiente,
        feedbackMessage: 'Pendiente de validación de pago',
        feedbackType: FeedbackType.error,
        feedbackId: 1,
      ),
    ],
  );
}
