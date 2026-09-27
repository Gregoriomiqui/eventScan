import 'package:event_scan/core/network/api_config.dart';
import 'package:event_scan/core/network/app_supabase_client.dart';
import 'package:event_scan/core/theme/app_theme.dart';
import 'package:event_scan/features/check_in/data/datasources/supabase_remote_data_source.dart';
import 'package:event_scan/features/check_in/data/repositories/check_in_repository_impl.dart';
import 'package:event_scan/features/check_in/domain/usecases/confirm_check_in.dart';
import 'package:event_scan/features/check_in/domain/usecases/get_attendee_by_uid.dart';
import 'package:event_scan/features/check_in/presentation/pages/check_in_page.dart';
import 'package:event_scan/features/check_in/presentation/state/check_in_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase/supabase.dart';

void main() {
  final apiConfig = ApiConfig.fromEnvironment();
  if (!apiConfig.hasValidSupabaseConfig) {
    runApp(const MissingConfigApp());
    return;
  }

  final supabaseClient = SupabaseClient(
    apiConfig.supabaseUrl,
    apiConfig.supabaseAnonKey,
  );
  final client = SupabaseAppClient(supabaseClient);
  final remoteDataSource = SupabaseRemoteDataSourceImpl(
    client: client,
    apiConfig: apiConfig,
  );
  final repository = CheckInRepositoryImpl(remoteDataSource);

  runApp(
    EventScanApp(
      getAttendeeByUid: GetAttendeeByUidUseCase(repository),
      confirmCheckIn: ConfirmCheckInUseCase(repository),
    ),
  );
}

class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Configuracion faltante de Supabase.\n\n'
              'Ejecuta la app con:\n'
              '--dart-define=SUPABASE_URL=...\n'
              '--dart-define=SUPABASE_ANON_KEY=...',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class EventScanApp extends StatelessWidget {
  const EventScanApp({
    super.key,
    required this.getAttendeeByUid,
    required this.confirmCheckIn,
  });

  final GetAttendeeByUidUseCase getAttendeeByUid;
  final ConfirmCheckInUseCase confirmCheckIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Event Scan',
      theme: AppTheme.light(),
      home: BlocProvider(
        create: (_) => CheckInBloc(
          getAttendeeByUid: getAttendeeByUid,
          confirmCheckIn: confirmCheckIn,
        ),
        child: const CheckInPage(),
      ),
    );
  }
}
