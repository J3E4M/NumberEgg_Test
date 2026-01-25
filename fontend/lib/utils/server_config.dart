class ServerConfig {
  static const String _defaultBaseUrl = 'http://10.0.2.2:8000'; // For emulator connection
  
  /// ดึง URL สำหรับการตรวจจับ
  static Future<String> getDetectUrl() async {
    // สำหรับ emulator ใช้ 10.0.2.2
    // สำหรับ device จริงต้องใช้ IP address ของเครื่องที่รัน server
    return '$_defaultBaseUrl/detect';
  }
  
  /// ดึง URL สำหรับ API อื่นๆ
  static Future<String> getApiUrl() async {
    return _defaultBaseUrl;
  }
}
