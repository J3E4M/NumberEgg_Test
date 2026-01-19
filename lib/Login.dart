import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

Logger log = Logger();

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final dio = Dio();

  String? _errorMessage;
  Map<String, dynamic>? result;

  Future<void> _login() async {
    // const serverURL = 'https://mobile.wattanapong.com/api/auth/login';

    // try {
    //   final response = await dio.post(
    //     serverURL,
    //     data: {
    //       'email': _emailController.text,
    //       'pass': _passwordController.text,
    //     },
    //   );
      

      // if (response.statusCode == 200) {
      //   final data = response.data;
      //   final prefs = await SharedPreferences.getInstance();
      //   prefs.setString('name', data['member']['name']);
      //   prefs.setString('email', data['member']['email']);

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/member');
        }
      // }
    } //on DioException catch (e) {
  //     setState(() {
  //       _errorMessage = e.response?.data['message'] ?? e.message;
  //     });
  //   }
  // }

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
                const SizedBox(height: 24),

                // 🔙 Back button
                CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(height: 24),

                // 🥚 Logo
                Center(
                  child: Image.asset(
                    'assets/images/number_egg_logo.png',
                    width: 230,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 36),

                // 🔁 Toggle Login / Register
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      // LOGIN (active)
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE082),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'เข้าสู่ระบบ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      // REGISTER
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(
                                context, '/register');
                          },
                          child: const Center(
                            child: Text(
                              'สมัครสมาชิก',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 📧 Email
                const Text('Email'),
                const SizedBox(height: 8),
                _inputField(
                  controller: _emailController,
                  icon: Icons.mail,
                  hint: 'farmer@number.egg.com',
                ),

                const SizedBox(height: 16),

                // 🔒 Password
                const Text('Password'),
                const SizedBox(height: 8),
                _inputField(
                  controller: _passwordController,
                  icon: Icons.lock,
                  hint: '***********',
                  obscure: true,
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Color(0xFFFFB300)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ✅ Confirm button
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
                    onPressed: _login,
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

  // ---------- INPUT FIELD ----------
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
