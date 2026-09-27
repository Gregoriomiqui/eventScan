class ApiConfig {
  const ApiConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.attendeesTable = 'registered',
    this.enrollmentCodeColumn = 'CODIGO_INSCRIPCION',
    this.rutColumn = 'RUT',
    this.timeoutSeconds = 15,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String attendeesTable;
  final String enrollmentCodeColumn;
  final String rutColumn;
  final int timeoutSeconds;

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
      enrollmentCodeColumn: String.fromEnvironment(
        'SUPABASE_ENROLLMENT_CODE_COLUMN',
        defaultValue: 'CODIGO_INSCRIPCION',
      ),
      rutColumn: String.fromEnvironment(
        'SUPABASE_RUT_COLUMN',
        defaultValue: 'RUT',
      ),
    );
  }
}
