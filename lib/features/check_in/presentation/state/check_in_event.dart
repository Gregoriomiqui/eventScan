abstract class CheckInEvent {
  const CheckInEvent();
}

class UidUpdated extends CheckInEvent {
  const UidUpdated(this.uid);

  final String uid;
}

class QrDetected extends CheckInEvent {
  const QrDetected(this.rawValue);

  final String rawValue;
}

class ValidateRequested extends CheckInEvent {
  const ValidateRequested();
}

class ConfirmCheckInRequested extends CheckInEvent {
  const ConfirmCheckInRequested();
}

class ResetFlowRequested extends CheckInEvent {
  const ResetFlowRequested();
}

class FeedbackConsumed extends CheckInEvent {
  const FeedbackConsumed();
}
