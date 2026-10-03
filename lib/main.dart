import 'package:event_scan/core/network/api_config.dart';
import 'package:event_scan/core/network/app_supabase_client.dart';
import 'package:event_scan/core/theme/app_theme.dart';
import 'package:event_scan/features/check_in/data/datasources/supabase_remote_data_source.dart';
import 'package:event_scan/features/check_in/data/repositories/check_in_repository_impl.dart';
import 'package:event_scan/features/check_in/data/services/check_in_pdf_export_service.dart';
import 'package:event_scan/features/check_in/domain/usecases/confirm_check_in.dart';
import 'package:event_scan/features/check_in/domain/usecases/get_attendee_by_uid.dart';
import 'package:event_scan/features/check_in/presentation/pages/check_in_mode_page.dart';
import 'package:flutter/material.dart';
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
  final pdfExportService = CheckInPdfExportService(
    client: client,
    timeout: Duration(seconds: apiConfig.timeoutSeconds),
  );

  final attendeeDataSource = SupabaseRemoteDataSourceImpl(
    client: client,
    apiConfig: apiConfig,
  );
  final attendeeRepository = CheckInRepositoryImpl(attendeeDataSource);

  final staffApiConfig = apiConfig.copyWith(
    attendeesTable: apiConfig.staffTable,
    enrollmentCodeColumn: apiConfig.staffEnrollmentCodeColumn,
    rutColumn: apiConfig.staffRutColumn,
  );
  final staffDataSource = SupabaseRemoteDataSourceImpl(
    client: client,
    apiConfig: staffApiConfig,
  );
  final staffRepository = CheckInRepositoryImpl(staffDataSource);

  runApp(
    EventScanApp(
      attendeeGetAttendeeByUid: GetAttendeeByUidUseCase(attendeeRepository),
      attendeeConfirmCheckIn: ConfirmCheckInUseCase(attendeeRepository),
      staffGetAttendeeByUid: GetAttendeeByUidUseCase(staffRepository),
      staffConfirmCheckIn: ConfirmCheckInUseCase(staffRepository),
      exportAttendeesPdf: (onStageChanged) => pdfExportService.exportTable(
        table: apiConfig.attendeesTable,
        reportTitle: 'Listado de Asistentes',
        additionalExcludedColumns: const {'ID_TALLER_AM', 'ID_TALLER_PM'},
        onStageChanged: onStageChanged,
      ),
      exportStaffPdf: (onStageChanged) => pdfExportService.exportTable(
        table: apiConfig.staffTable,
        reportTitle: 'Listado de Staff',
        onStageChanged: onStageChanged,
      ),
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
    required this.attendeeGetAttendeeByUid,
    required this.attendeeConfirmCheckIn,
    required this.staffGetAttendeeByUid,
    required this.staffConfirmCheckIn,
    this.exportAttendeesPdf,
    this.exportStaffPdf,
  });

  final GetAttendeeByUidUseCase attendeeGetAttendeeByUid;
  final ConfirmCheckInUseCase attendeeConfirmCheckIn;
  final GetAttendeeByUidUseCase staffGetAttendeeByUid;
  final ConfirmCheckInUseCase staffConfirmCheckIn;
  final Future<void> Function(void Function(String stage) onStageChanged)?
  exportAttendeesPdf;
  final Future<void> Function(void Function(String stage) onStageChanged)?
  exportStaffPdf;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Event Scan',
      theme: AppTheme.light(),
      home: CheckInModePage(
        attendeeGetAttendeeByUid: attendeeGetAttendeeByUid,
        attendeeConfirmCheckIn: attendeeConfirmCheckIn,
        staffGetAttendeeByUid: staffGetAttendeeByUid,
        staffConfirmCheckIn: staffConfirmCheckIn,
        exportAttendeesPdf: exportAttendeesPdf,
        exportStaffPdf: exportStaffPdf,
      ),
    );
  }
}
