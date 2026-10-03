import 'package:event_scan/core/error/result.dart';
import 'package:event_scan/features/check_in/domain/usecases/confirm_check_in.dart';
import 'package:event_scan/features/check_in/domain/usecases/get_attendee_by_uid.dart';
import 'package:event_scan/features/check_in/domain/value_objects/uid.dart';
import 'package:event_scan/features/check_in/presentation/state/check_in_event.dart';
import 'package:event_scan/features/check_in/presentation/state/check_in_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CheckInBloc extends Bloc<CheckInEvent, CheckInState> {
  CheckInBloc({
    required GetAttendeeByUidUseCase getAttendeeByUid,
    required ConfirmCheckInUseCase confirmCheckIn,
    DateTime Function()? now,
  }) : _getAttendeeByUid = getAttendeeByUid,
       _confirmCheckIn = confirmCheckIn,
       _now = now ?? DateTime.now,
       super(const CheckInState()) {
    on<UidUpdated>(_onUidUpdated);
    on<QrDetected>(_onQrDetected);
    on<ValidateRequested>(_onValidateRequested);
    on<ConfirmCheckInRequested>(_onConfirmCheckInRequested);
    on<ResetFlowRequested>(_onResetFlowRequested);
    on<FeedbackConsumed>(_onFeedbackConsumed);
  }

  final GetAttendeeByUidUseCase _getAttendeeByUid;
  final ConfirmCheckInUseCase _confirmCheckIn;
  final DateTime Function() _now;

  void _onUidUpdated(UidUpdated event, Emitter<CheckInState> emit) {
    emit(
      state.copyWith(
        uid: event.uid,
        clearAttendee: true,
        canScanNext: false,
      ),
    );
  }

  void _onQrDetected(QrDetected event, Emitter<CheckInState> emit) {
    final parsed = Uid.tryParse(event.rawValue);
    if (parsed == null) {
      if (state.uid.trim().isNotEmpty) {
        return;
      }

      emit(
        state.copyWith(
          feedbackMessage: 'Código de inscripción o RUT no válido',
          feedbackType: FeedbackType.error,
          feedbackId: state.feedbackId + 1,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        uid: parsed.value,
        clearAttendee: true,
        canScanNext: false,
        feedbackMessage: 'UID capturado desde QR',
        feedbackType: FeedbackType.info,
        feedbackId: state.feedbackId + 1,
      ),
    );
  }

  Future<void> _onValidateRequested(
    ValidateRequested event,
    Emitter<CheckInState> emit,
  ) async {
    emit(
      state.copyWith(
        isValidating: true,
        clearAttendee: true,
        canScanNext: false,
        clearFeedback: true,
      ),
    );

    final result = await _getAttendeeByUid(state.uid);
    if (result is Success<dynamic>) {
      final success = result as Success<dynamic>;
      final attendee = success.value;
      final isPagoPendiente = attendee.isPagoPendiente;
      emit(
        state.copyWith(
          isValidating: false,
          attendee: attendee,
          feedbackMessage: isPagoPendiente
              ? 'Pendiente de validación de pago'
              : 'Registro encontrado. Listo para check-in.',
          feedbackType: isPagoPendiente ? FeedbackType.error : FeedbackType.info,
          feedbackId: state.feedbackId + 1,
        ),
      );
      return;
    }

    final failure = (result as Error).failure;
    emit(
      state.copyWith(
        isValidating: false,
        clearAttendee: true,
        feedbackMessage: failure.message,
        feedbackType: FeedbackType.error,
        feedbackId: state.feedbackId + 1,
      ),
    );
  }

  Future<void> _onConfirmCheckInRequested(
    ConfirmCheckInRequested event,
    Emitter<CheckInState> emit,
  ) async {
    if (state.attendee == null) {
      emit(
        state.copyWith(
          feedbackMessage: 'Primero valida un asistente antes de confirmar.',
          feedbackType: FeedbackType.error,
          feedbackId: state.feedbackId + 1,
        ),
      );
      return;
    }

    if (state.attendee!.isPagoPendiente) {
      emit(
        state.copyWith(
          feedbackMessage: 'Pendiente de validación de pago',
          feedbackType: FeedbackType.error,
          feedbackId: state.feedbackId + 1,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isConfirming: true,
        clearFeedback: true,
      ),
    );

    final result = await _confirmCheckIn(uid: state.uid, checkedInAt: _now());
    if (result is Success<void>) {
      emit(
        state.copyWith(
          uid: '',
          isConfirming: false,
          clearAttendee: true,
          canScanNext: true,
          feedbackMessage: 'Check-in completado exitosamente',
          feedbackType: FeedbackType.success,
          feedbackId: state.feedbackId + 1,
        ),
      );
      return;
    }

    final failure = (result as Error<void>).failure;
    emit(
      state.copyWith(
        isConfirming: false,
        feedbackMessage: failure.message,
        feedbackType: FeedbackType.error,
        feedbackId: state.feedbackId + 1,
      ),
    );
  }

  void _onResetFlowRequested(
    ResetFlowRequested event,
    Emitter<CheckInState> emit,
  ) {
    emit(const CheckInState());
  }

  void _onFeedbackConsumed(FeedbackConsumed event, Emitter<CheckInState> emit) {
    emit(state.copyWith(clearFeedback: true));
  }
}
