import 'package:event_scan/core/error/result.dart';
import 'package:event_scan/features/check_in/domain/entities/attendee.dart';
import 'package:event_scan/features/check_in/domain/repositories/check_in_repository.dart';
import 'package:event_scan/features/check_in/domain/usecases/confirm_check_in.dart';
import 'package:event_scan/features/check_in/domain/usecases/get_attendee_by_uid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:event_scan/main.dart';

class _FakeRepository implements CheckInRepository {
  @override
  Future<Result<void>> confirmCheckIn({
    required String uid,
    required DateTime checkedInAt,
  }) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<Attendee>> getAttendeeByUid(String uid) async {
    return const Success<Attendee>(
      Attendee(
        rut: '1-9',
        nombre: 'Ana',
        apellido: 'Diaz',
        email: 'ana@test.com',
        telefono: '+56911111111',
        distrito: 'Centro',
        iglesia: 'Luz',
        tallerAm: 'Oracion',
        tallerPm: 'Servicio',
      ),
    );
  }
}

void main() {
  testWidgets('app boots with check-in page', (WidgetTester tester) async {
    final repository = _FakeRepository();

    await tester.pumpWidget(
      EventScanApp(
        getAttendeeByUid: GetAttendeeByUidUseCase(repository),
        confirmCheckIn: ConfirmCheckInUseCase(repository),
      ),
    );

    expect(find.text('Check-in de Asistentes'), findsOneWidget);
    expect(find.text('UID del asistente'), findsOneWidget);
  });
}
