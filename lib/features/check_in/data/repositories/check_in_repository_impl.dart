import 'package:event_scan/core/error/exceptions.dart';
import 'package:event_scan/core/error/failures.dart';
import 'package:event_scan/core/error/result.dart';
import 'package:event_scan/features/check_in/data/datasources/supabase_remote_data_source.dart';
import 'package:event_scan/features/check_in/domain/entities/attendee.dart';
import 'package:event_scan/features/check_in/domain/repositories/check_in_repository.dart';

class CheckInRepositoryImpl implements CheckInRepository {
  CheckInRepositoryImpl(this._remoteDataSource);

  final SupabaseRemoteDataSource _remoteDataSource;

  @override
  Future<Result<Attendee>> getAttendeeByUid(String uid) async {
    try {
      final attendee = await _remoteDataSource.getAttendeeByUid(uid);
      return Success<Attendee>(attendee);
    } on NotFoundException catch (exception) {
      return Error<Attendee>(NotFoundFailure(exception.message));
    } on NetworkException catch (exception) {
      return Error<Attendee>(NetworkFailure(exception.message));
    } on ServerException catch (exception) {
      return Error<Attendee>(ServerFailure(exception.message));
    } catch (_) {
      return const Error<Attendee>(UnexpectedFailure('Error inesperado'));
    }
  }

  @override
  Future<Result<void>> confirmCheckIn({
    required String uid,
    required DateTime checkedInAt,
  }) async {
    try {
      await _remoteDataSource.confirmCheckIn(uid: uid, checkedInAt: checkedInAt);
      return const Success<void>(null);
    } on NotFoundException catch (exception) {
      return Error<void>(NotFoundFailure(exception.message));
    } on NetworkException catch (exception) {
      return Error<void>(NetworkFailure(exception.message));
    } on ServerException catch (exception) {
      return Error<void>(ServerFailure(exception.message));
    } catch (_) {
      return const Error<void>(UnexpectedFailure('Error inesperado'));
    }
  }
}
