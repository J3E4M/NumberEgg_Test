class SupabaseConfig {
  // ข้อมูลจริงจาก Supabase project
  static const String supabaseUrl = 'https://gbxxwojlihgrbtthmusq.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdieHh3b2psaWhncmJ0dGhtdXNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM5NTQ1MjYsImV4cCI6MjA3OTUzMDUyNn0.-XKw6NOhrWBxp4gLvQbPExLU2PHhUfUWdD3zsSc_9_k';
  
  /// ดึง Supabase URL
  static String get url => supabaseUrl;
  
  /// ดึง Supabase Anonymous Key
  static String get anonKey => supabaseAnonKey;
  
  /// ตรวจสอบว่ามีการตั้งค่าครบถ้วนหรือไม่
  static bool get isConfigured {
    return supabaseUrl != 'https://your-project-id.supabase.co' && 
           supabaseAnonKey != 'your-anon-key';
  }
}
