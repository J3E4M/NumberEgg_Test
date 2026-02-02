class ServerConfig {
  static const String _supabaseUrl = 'https://gbxxwojlihgrbtthmusq.supabase.co'; // Supabase URL
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdieHh3b2psaWhncmJ0dGhtdXNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM5NTQ1MjYsImV4cCI6MjA3OTUzMDUyNn0.-XKw6NOhrWBxp4gLvQbPExLU2PHhUfUWdD3zsSc_9_k';
  static const String _railwayUrl = 'https://numbereggrailway-production.up.railway.app'; // Railway URL (production)
  
  /// ดึง URL สำหรับการตรวจจับ (Railway)
  static Future<String> getDetectUrl() async {
    return '$_railwayUrl/detect';
  }
  
  /// ดึง URL สำหรับ API อื่นๆ (Supabase)
  static Future<String> getApiUrl() async {
    return _supabaseUrl;
  }
  
  /// ดึง Railway URL สำหรับ YOLO detection
  static String getRailwayUrl() {
    return _railwayUrl;
  }
  
  /// ดึง Supabase URL
  static String getSupabaseUrl() {
    return _supabaseUrl;
  }
  
  /// ดึง Supabase Anon Key
  static String getSupabaseAnonKey() {
    return _supabaseAnonKey;
  }
}
