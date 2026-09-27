import 'package:event_scan/core/error/failures.dart';
import 'package:event_scan/core/error/result.dart';
import 'package:event_scan/features/check_in/domain/repositories/check_in_repository.dart';
import 'package:event_scan/features/check_in/domain/value_objects/uid.dart';

class ConfirmCheckInUseCase {
  const ConfirmCheckInUseCase(this._repository);

  final CheckInRepository _repository;

  Future<Result<void>> call({
    required String uid,
    required DateTime checkedInAt,
  }) {
    if (!Uid.isValid(uid)) {
      return Future.value(
        const Error<void>(ValidationFailure('UID invalido para check-in')),
      );
    }

    return _repository.confirmCheckIn(uid: uid.trim(), checkedInAt: checkedInAt);
  }
}
