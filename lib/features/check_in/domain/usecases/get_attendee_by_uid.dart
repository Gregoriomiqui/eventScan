import 'package:event_scan/core/error/failures.dart';
import 'package:event_scan/core/error/result.dart';
import 'package:event_scan/features/check_in/domain/entities/attendee.dart';
import 'package:event_scan/features/check_in/domain/repositories/check_in_repository.dart';
import 'package:event_scan/features/check_in/domain/value_objects/uid.dart';

class GetAttendeeByUidUseCase {
  const GetAttendeeByUidUseCase(this._repository);

  final CheckInRepository _repository;

  Future<Result<Attendee>> call(String uid) {
    final parsed = Uid.tryParse(uid);
    if (parsed == null) {
      return Future.value(
        const Error<Attendee>(
          ValidationFailure('Codigo de inscripcion o RUT no valido'),
        ),
      );
    }

    return _repository.getAttendeeByUid(parsed.value);
  }
}
