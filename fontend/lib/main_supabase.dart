import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'camera.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ตรวจสอบว่ามีการตั้งค่า Supabase หรือไม่
  if (!SupabaseConfig.isConfigured) {
    debugPrint('❌ กรุณาตั้งค่า Supabase ใน lib/config/supabase_config.dart');
    return;
  }
  
  // เชื่อมต่อกับ Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    debug: true, // เปิด debug mode ในการพัฒนา
  );
  
  debugPrint('✅ เชื่อมต่อ Supabase สำเร็จ');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NumberEgg',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SelectImageScreen(),
    );
  }
}
