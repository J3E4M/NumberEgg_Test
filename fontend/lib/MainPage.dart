// หน้าแรกของแอปพลิเคชัน - หน้าเริ่มต้นก่อน login
import 'package:flutter/material.dart';

// Widget หน้าแรก (Splash/Welcome Screen)
class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF7CC), // สีเหลืองอ่อนด้านบน
              Colors.white,      // สีขาวตรงกลาง
              Color(0xFFFFF7CC), // สีเหลืองอ่อนด้านล่าง
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(), // ช่องว่างด้านบน

              // ---------- LOGO ----------
              // แสดงโลโก้ Number Egg
              Center(
                child: Image.asset(
                  'assets/images/number_egg_logo1.png',
                  width: 230,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 40), // ระยะห่าง

              // ---------- BUTTONS ----------
              // ปุ่มสแกนไข่
              _mainButton(
                text: "สแกนไข่",
                icon: Icons.camera_alt,
                color: const Color(0xFFFFB300), // สีเหลือง
                onTap: () {
                  Navigator.pushNamed(context, '/camera');
                },
              ),

              const SizedBox(height: 14), // ระยะห่างระหว่างปุ่ม

              // ปุ่มเข้าสู่ระบบ
              _mainButton(
                text: "เข้าสู่ระบบ",
                icon: Icons.person,
                color: const Color(0xFF2196F3), // สีฟ้า
                onTap: () {
                  Navigator.pushNamed(context, '/login');
                },
              ),

              const SizedBox(height: 14), // ระยะห่างระหว่างปุ่ม

              // ปุ่มสมัครสมาชิก
              _mainButton(
                text: "สมัครสมาชิก",
                icon: Icons.edit,
                color: const Color(0xFF2196F3), // สีฟ้า
                onTap: () {
                  Navigator.pushNamed(context, '/register');
                },
              ),

              const Spacer(), // ช่องว่างด้านล่าง

              // ---------- FOOTER ----------
              // ข้อความเวอร์ชัน
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  "Version Beta",
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- REUSABLE BUTTON ----------
  // ฟังก์ชันสร้างปุ่มหลักที่ใช้ซ้ำ
  static Widget _mainButton({
    required String text, // ข้อความบนปุ่ม
    required IconData icon, // ไอคอน
    required Color color, // สีปุ่ม
    required VoidCallback onTap, // เหตุการณ์เมื่อกด
  }) {
    return SizedBox(
      width: 230,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white, // สีข้อความ
          elevation: 6, // เงา
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // ขอบมน
          ),
        ),
      ),
    );
  }
}
