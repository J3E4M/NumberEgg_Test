// ไฟล์หลักสำหรับรันแอปพลิเคชัน Number Egg
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';

// นำเข้าหน้าต่างๆ ทั้งหมด
import '/MainPage.dart';
import '/ProfileSettingPage.dart';
import '/camera.dart';
import '/HomePage.dart';
import '/ProfilePage.dart';
import '/HistoryPage.dart';
import '/ResultPage.dart';
import '/Login.dart';
import '/Register.dart';

// ฟังก์ชันหลักสำหรับเริ่มรันแอป
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ตรวจสอบว่ามีการตั้งค่า Supabase หรือไม่
  if (!SupabaseConfig.isConfigured) {
    debugPrint('❌ กรุณาตั้งค่า Supabase ใน lib/config/supabase_config.dart');
    // ยังคงรันแอปได้แต่จะไม่มีฟีเจอร์ Supabase
  } else {
    // เชื่อมต่อกับ Supabase
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        debug: true, // เปิด debug mode ในการพัฒนา
      );
      debugPrint('✅ เชื่อมต่อ Supabase สำเร็จ');
    } catch (e) {
      debugPrint('❌ เชื่อมต่อ Supabase ล้มเหลว: $e');
      // ยังคงรันแอปได้แต่จะไม่มีฟีเจอร์ Supabase
    }
  }
  
  runApp(const LinkPage());
}

// Widget หลักของแอปพลิเคชัน
class LinkPage extends StatelessWidget {
  const LinkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // ซ่อนแถบ debug

      initialRoute: '/', // หน้าแรกที่แสดง
      routes: {
        '/': (context) => MainPage(), // หน้าหลัก
        '/login': (context) => LoginPage(), // หน้าเข้าสู่ระบบ
        '/register': (context) => RegisterPage(), // หน้าสมัครสมาชิก
        '/camera': (context) => const SelectImageScreen(), // หน้ากล้องถ่ายรูป
        '/member': (context) => const HomePage(), // หน้าสมาชิก (หน้าแรกหลัง login)
        '/profile': (context) => const ProfilePage(), // หน้าโปรไฟล์
        '/history': (context) => const HistoryPage(), // หน้าประวัติ
        '/result': (context) => const ResultPage(), // หน้าผลลัพธ์
      },
    );
  }
}
