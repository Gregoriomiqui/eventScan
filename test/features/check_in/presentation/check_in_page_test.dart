import 'package:bloc_test/bloc_test.dart';
import 'package:event_scan/features/check_in/domain/entities/attendee.dart';
import 'package:event_scan/features/check_in/presentation/pages/check_in_page.dart';
import 'package:event_scan/features/check_in/presentation/state/check_in_bloc.dart';
import 'package:event_scan/features/check_in/presentation/state/check_in_event.dart';
import 'package:event_scan/features/check_in/presentation/state/check_in_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCheckInBloc extends MockBloc<CheckInEvent, CheckInState>
    implements CheckInBloc {}

class _FakeCheckInEvent extends Fake implements CheckInEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeCheckInEvent());
  });

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

  const checkedInAttendee = Attendee(
    rut: '1-9',
    nombre: 'Ana',
    apellido: 'Diaz',
    email: 'ana@test.com',
    telefono: '+56911111111',
    distrito: 'Centro',
    iglesia: 'Luz',
    tallerAm: 'Oracion',
    tallerPm: 'Servicio',
    checkIn: true,
  );

  const pendingPaymentAttendee = Attendee(
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

  Widget buildWidget(_MockCheckInBloc bloc) {
    return MaterialApp(
      home: BlocProvider<CheckInBloc>.value(
        value: bloc,
        child: const CheckInPage(
          scannerOverride: SizedBox(height: 220),
        ),
      ),
    );
  }

  testWidgets('renders attendee card when state has attendee', (tester) async {
    final bloc = _MockCheckInBloc();
    const state = CheckInState(uid: '550e8400-e29b-41d4-a716-446655440000', attendee: attendee);
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, const Stream<CheckInState>.empty(), initialState: state);

    await tester.pumpWidget(buildWidget(bloc));

    expect(find.text('Ana Diaz'), findsOneWidget);
    expect(find.text('ana@test.com'), findsOneWidget);
  });

  testWidgets('dispatches confirm check-in when green button is tapped', (tester) async {
    final bloc = _MockCheckInBloc();
    const state = CheckInState(uid: '550e8400-e29b-41d4-a716-446655440000', attendee: attendee);
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, const Stream<CheckInState>.empty(), initialState: state);

    await tester.pumpWidget(buildWidget(bloc));
    await tester.tap(find.text('Confirmar Check-in'));

    verify(() => bloc.add(const ConfirmCheckInRequested())).called(1);
  });

  testWidgets('disables confirm button when attendee already checked in', (
    tester,
  ) async {
    final bloc = _MockCheckInBloc();
    const state = CheckInState(
      uid: '550e8400-e29b-41d4-a716-446655440000',
      attendee: checkedInAttendee,
    );
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, const Stream<CheckInState>.empty(), initialState: state);

    await tester.pumpWidget(buildWidget(bloc));

    expect(find.text('Ya realizo check-in'), findsOneWidget);

    final confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirmar Check-in'),
    );
    expect(confirm.onPressed, isNull);
  });

  testWidgets('disables confirm button when payment is pending', (tester) async {
    final bloc = _MockCheckInBloc();
    const state = CheckInState(
      uid: '550e8400-e29b-41d4-a716-446655440000',
      attendee: pendingPaymentAttendee,
    );
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, const Stream<CheckInState>.empty(), initialState: state);

    await tester.pumpWidget(buildWidget(bloc));

    final confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirmar Check-in'),
    );
    expect(confirm.onPressed, isNull);
  });

  testWidgets('shows reset button and clears uid after successful confirmation', (tester) async {
    final bloc = _MockCheckInBloc();
    const state = CheckInState(
      uid: '',
      canScanNext: true,
      feedbackMessage: 'Check-in completado exitosamente',
      feedbackType: FeedbackType.success,
      feedbackId: 1,
    );
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await tester.pumpWidget(buildWidget(bloc));
    await tester.pumpAndSettle();

    expect(find.text('Escanear siguiente QR'), findsOneWidget);

    final textField = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(textField.controller?.text ?? '', isEmpty);

    await tester.tap(find.text('Escanear siguiente QR'));
    verify(() => bloc.add(const ResetFlowRequested())).called(1);
  });
}
