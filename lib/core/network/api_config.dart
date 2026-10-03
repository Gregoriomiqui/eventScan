class ApiConfig {
  const ApiConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.attendeesTable = 'registered',
    this.staffTable = 'staff',
    this.enrollmentCodeColumn = 'CODIGO_INSCRIPCION',
    this.rutColumn = 'RUT',
    this.staffEnrollmentCodeColumn = 'CODIGO_INSCRIPCION',
    this.staffRutColumn = 'RUT',
    this.timeoutSeconds = 15,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String attendeesTable;
  final String staffTable;
  final String enrollmentCodeColumn;
  final String rutColumn;
  final String staffEnrollmentCodeColumn;
  final String staffRutColumn;
  final int timeoutSeconds;

  ApiConfig copyWith({
    String? supabaseUrl,
    String? supabaseAnonKey,
    String? attendeesTable,
    String? staffTable,
    String? enrollmentCodeColumn,
    String? rutColumn,
    String? staffEnrollmentCodeColumn,
    String? staffRutColumn,
    int? timeoutSeconds,
  }) {
    return ApiConfig(
      supabaseUrl: supabaseUrl ?? this.supabaseUrl,
      supabaseAnonKey: supabaseAnonKey ?? this.supabaseAnonKey,
      attendeesTable: attendeesTable ?? this.attendeesTable,
      staffTable: staffTable ?? this.staffTable,
      enrollmentCodeColumn: enrollmentCodeColumn ?? this.enrollmentCodeColumn,
      rutColumn: rutColumn ?? this.rutColumn,
      staffEnrollmentCodeColumn:
          staffEnrollmentCodeColumn ?? this.staffEnrollmentCodeColumn,
      staffRutColumn: staffRutColumn ?? this.staffRutColumn,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    );
  }

  bool get hasValidSupabaseConfig {
    final invalidUrl =
        supabaseUrl.isEmpty ||
        supabaseUrl.contains('your-project.supabase.co');
    final invalidAnonKey =
        supabaseAnonKey.isEmpty || supabaseAnonKey == 'replace-with-anon-key';

    return !invalidUrl && !invalidAnonKey;
  }

  factory ApiConfig.fromEnvironment() {
    return const ApiConfig(
      supabaseUrl: String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://your-project.supabase.co',
      ),
      supabaseAnonKey: String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: 'replace-with-anon-key',
      ),
      attendeesTable: String.fromEnvironment(
        'SUPABASE_ATTENDEES_TABLE',
        defaultValue: 'registered',
      ),
      staffTable: String.fromEnvironment(
        'SUPABASE_STAFF_TABLE',
        defaultValue: 'staff',
      ),
      enrollmentCodeColumn: String.fromEnvironment(
        'SUPABASE_ENROLLMENT_CODE_COLUMN',
        defaultValue: 'CODIGO_INSCRIPCION',
      ),
      rutColumn: String.fromEnvironment(
        'SUPABASE_RUT_COLUMN',
        defaultValue: 'RUT',
      ),
      staffEnrollmentCodeColumn: String.fromEnvironment(
        'SUPABASE_STAFF_ENROLLMENT_CODE_COLUMN',
        defaultValue: 'CODIGO_INSCRIPCION',
      ),
      staffRutColumn: String.fromEnvironment(
        'SUPABASE_STAFF_RUT_COLUMN',
        defaultValue: 'RUT',
      ),
    );
  }
}
