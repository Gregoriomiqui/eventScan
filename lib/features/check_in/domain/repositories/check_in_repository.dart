import 'package:event_scan/core/error/result.dart';
import 'package:event_scan/features/check_in/domain/entities/attendee.dart';

abstract class CheckInRepository {
  Future<Result<Attendee>> getAttendeeByUid(String uid);

  Future<Result<void>> confirmCheckIn({
    required String uid,
    required DateTime checkedInAt,
  });
}
