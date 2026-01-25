import 'package:flutter/material.dart';

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
              Color(0xFFFFF7CC),
              Colors.white,
              Color(0xFFFFF7CC),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              // ---------- LOGO ----------
              Center(
                child: Image.asset(
                  'assets/images/number_egg_logo1.png',
                  width: 230,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 40),

              // ---------- BUTTONS ----------
              _mainButton(
                text: "สแกนไข่",
                icon: Icons.camera_alt,
                color: const Color(0xFFFFB300),
                onTap: () {
                  Navigator.pushNamed(context, '/main');
                },
              ),

              const SizedBox(height: 14),

              _mainButton(
                text: "เข้าสู่ระบบ",
                icon: Icons.person,
                color: const Color(0xFF2196F3),
                onTap: () {
                  Navigator.pushNamed(context, '/login');
                },
              ),

              const SizedBox(height: 14),

              _mainButton(
                text: "สมัครสมาชิก",
                icon: Icons.edit,
                color: const Color(0xFF2196F3),
                onTap: () {
                  Navigator.pushNamed(context, '/register');
                },
              ),

              const Spacer(),

              // ---------- FOOTER ----------
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
  static Widget _mainButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
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
          foregroundColor: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
