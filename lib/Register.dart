import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

Logger log = Logger();

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final dio = Dio();
  String? _errorMessage;

  Future<void> register() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'กรุณากรอกข้อมูลให้ครบ');
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = 'รหัสผ่านไม่ตรงกัน');
      return;
    }

    try {
      await dio.post(
        'https://mobile.wattanapong.com/api/auth/register',
        data: {
          'email': email,
          'pass': password,
          'name': email.split('@').first,
        },
      );

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Register failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                /// 🔙 BACK TO MAIN
                CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/'),
                  ),
                ),

                const SizedBox(height: 24),

                /// 🥚 LOGO
                Center(
                  child: Image.asset(
                    'assets/images/number_egg_logo.png',
                    width: 230,  
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 32),

                /// 🔁 TOGGLE LOGIN / REGISTER
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: const Center(
                            child: Text(
                              'เข้าสู่ระบบ',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE082),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'สมัครสมาชิก',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                /// 📧 EMAIL
                const Text('Email'),
                const SizedBox(height: 8),
                _inputField(
                  controller: _emailController,
                  icon: Icons.mail,
                  hint: 'farmer@number.egg.com',
                ),

                const SizedBox(height: 16),

                /// 🔒 PASSWORD
                const Text('Password'),
                const SizedBox(height: 8),
                _inputField(
                  controller: _passwordController,
                  icon: Icons.lock,
                  hint: '************',
                  obscure: true,
                ),

                const SizedBox(height: 16),

                /// 🔒 CONFIRM
                const Text('Confirm Password'),
                const SizedBox(height: 8),
                _inputField(
                  controller: _confirmController,
                  icon: Icons.lock,
                  hint: '************',
                  obscure: true,
                ),

                const SizedBox(height: 28),

                /// ✅ CONFIRM BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF212121),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: register,
                    child: const Text(
                      'ยืนยัน',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                const Center(
                  child: Text(
                    'Version Beta',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE082),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          icon: Icon(icon),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
