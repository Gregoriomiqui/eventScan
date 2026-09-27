import 'package:event_scan/core/network/api_config.dart';
import 'package:event_scan/core/network/app_supabase_client.dart';
import 'package:event_scan/features/check_in/data/models/attendee_model.dart';

abstract class SupabaseRemoteDataSource {
  Future<AttendeeModel> getAttendeeByUid(String uid);

  Future<void> confirmCheckIn({required String uid, required DateTime checkedInAt});
}

class SupabaseRemoteDataSourceImpl implements SupabaseRemoteDataSource {
  SupabaseRemoteDataSourceImpl({
    required AppSupabaseClient client,
    required ApiConfig apiConfig,
  }) : _client = client,
       _apiConfig = apiConfig;

  final AppSupabaseClient _client;
  final ApiConfig _apiConfig;

  @override
  Future<AttendeeModel> getAttendeeByUid(String uid) async {
    final response = await _client.findAttendeeByUid(
      table: _apiConfig.attendeesTable,
      enrollmentCodeColumn: _apiConfig.enrollmentCodeColumn,
      rutColumn: _apiConfig.rutColumn,
      uid: uid,
      timeout: Duration(seconds: _apiConfig.timeoutSeconds),
    );

    return AttendeeModel.fromJson(response);
  }

  @override
  Future<void> confirmCheckIn({
    required String uid,
    required DateTime checkedInAt,
  }) {
    return _client.markCheckIn(
      table: _apiConfig.attendeesTable,
      enrollmentCodeColumn: _apiConfig.enrollmentCodeColumn,
      rutColumn: _apiConfig.rutColumn,
      uid: uid,
      checkedInAt: checkedInAt,
      timeout: Duration(seconds: _apiConfig.timeoutSeconds),
    );
  }
}
