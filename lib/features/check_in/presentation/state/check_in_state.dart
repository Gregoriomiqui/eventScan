import 'package:equatable/equatable.dart';
import 'package:event_scan/features/check_in/domain/entities/attendee.dart';

enum FeedbackType { success, error, info }

class CheckInState extends Equatable {
  const CheckInState({
    this.uid = '',
    this.attendee,
    this.isValidating = false,
    this.isConfirming = false,
    this.feedbackMessage,
    this.feedbackType,
    this.feedbackId = 0,
    this.canScanNext = false,
  });

  final String uid;
  final Attendee? attendee;
  final bool isValidating;
  final bool isConfirming;
  final String? feedbackMessage;
  final FeedbackType? feedbackType;
  final int feedbackId;
  final bool canScanNext;

  bool get isBusy => isValidating || isConfirming;

  CheckInState copyWith({
    String? uid,
    Attendee? attendee,
    bool clearAttendee = false,
    bool? isValidating,
    bool? isConfirming,
    String? feedbackMessage,
    FeedbackType? feedbackType,
    bool clearFeedback = false,
    int? feedbackId,
    bool? canScanNext,
  }) {
    return CheckInState(
      uid: uid ?? this.uid,
      attendee: clearAttendee ? null : (attendee ?? this.attendee),
      isValidating: isValidating ?? this.isValidating,
      isConfirming: isConfirming ?? this.isConfirming,
      feedbackMessage: clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      feedbackType: clearFeedback ? null : (feedbackType ?? this.feedbackType),
      feedbackId: feedbackId ?? this.feedbackId,
      canScanNext: canScanNext ?? this.canScanNext,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    attendee,
    isValidating,
    isConfirming,
    feedbackMessage,
    feedbackType,
    feedbackId,
    canScanNext,
  ];
}
