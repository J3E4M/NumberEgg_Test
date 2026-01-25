import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/user_database.dart';
import 'models/user.dart';

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
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'กรุณากรอกอีเมลและรหัสผ่าน';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ตรวจสอบว่าเป็น mock user หรือไม่ก่อน
      final prefs = await SharedPreferences.getInstance();
      final isMockRegistered = prefs.getBool('mock_registered') ?? false;
      
      if (isMockRegistered) {
        final savedEmail = prefs.getString('mock_email');
        final savedPassword = prefs.getString('mock_password');
        final savedName = prefs.getString('mock_name');
        
        if (_emailController.text.trim() == savedEmail && _passwordController.text == savedPassword) {
          // Login สำเร็จแบบ mock
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('user_email', savedEmail!);
          await prefs.setString('user_name', savedName!);
          await prefs.setString('user_privilege', 'User');
          
          // บันทึกการจดจำข้อมูลการเข้าสู่ระบบ
          await _saveCredentials();
          
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/member');
          }
          return;
        } else {
          setState(() => _errorMessage = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง');
          return;
        }
      }
      
      // ใช้ UserDatabase สำหรับการตรวจสอบการเข้าสู่ระบบ
      final loginResult = await UserDatabase.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (loginResult != null) {
        final user = loginResult['user'] as User;
        final prefs = await SharedPreferences.getInstance();
        
        // บันทึกข้อมูลการเข้าสู่ระบบ
        await prefs.setBool('is_logged_in', true);
        await prefs.setInt('user_id', user.id);
        await prefs.setString('user_email', user.email);
        await prefs.setString('user_name', user.name);
        await prefs.setString('user_privilege', user.privilegeNameDisplay);
        
        // บันทึกการจดจำข้อมูลการเข้าสู่ระบบ
        await _saveCredentials();
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/member');
        }
      } else {
        setState(() => _errorMessage = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง');
      }
    } catch (e) {
      // ถ้าเกิด connection error ให้ตรวจสอบว่ามี mock user หรือไม่
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('SocketException')) {
        
        final prefs = await SharedPreferences.getInstance();
        final isMockRegistered = prefs.getBool('mock_registered') ?? false;
        
        if (isMockRegistered) {
          final savedEmail = prefs.getString('mock_email');
          final savedPassword = prefs.getString('mock_password');
          final savedName = prefs.getString('mock_name');
          
          if (_emailController.text.trim() == savedEmail && _passwordController.text == savedPassword) {
            // Login สำเร็จแบบ mock
            await prefs.setBool('is_logged_in', true);
            await prefs.setString('user_email', savedEmail!);
            await prefs.setString('user_name', savedName!);
            await prefs.setString('user_privilege', 'User');
            
            // บันทึกการจดจำข้อมูลการเข้าสู่ระบบ
            await _saveCredentials();
            
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/member');
            }
            return;
          }
        }
        
        setState(() => _errorMessage = 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้\nกรุณาเปิดเซิร์ฟเวอร์หรือสมัครสมาชิกในโหมดทดสอบ');
      } else {
        setState(() => _errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final savedPassword = prefs.getString('saved_password');
      final rememberMe = prefs.getBool('remember_me') ?? false;

      if (mounted) {
        setState(() {
          _rememberMe = rememberMe;
          if (rememberMe && savedEmail != null && savedPassword != null) {
            _emailController.text = savedEmail;
            _passwordController.text = savedPassword;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_rememberMe) {
        await prefs.setString('saved_email', _emailController.text.trim());
        await prefs.setString('saved_password', _passwordController.text);
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
        await prefs.setBool('remember_me', false);
      }
    } catch (e) {
      debugPrint('Error saving credentials: $e');
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
                  obscure: _obscurePassword,
                  showPasswordToggle: true,
                  onTogglePassword: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // 📝 Remember Me & Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Remember Me Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFFFFC107),
                        ),
                        const Text(
                          'จดจำการเข้าระบบ',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    
                    // Forgot Password
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Color(0xFFFFB300)),
                      ),
                    ),
                  ],
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
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('กำลังเข้าสู่ระบบ...'),
                            ],
                          )
                        : const Text(
                            'ยืนยัน',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),

                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          ),
                        ],
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
    bool showPasswordToggle = false,
    VoidCallback? onTogglePassword,
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
          suffixIcon: showPasswordToggle
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.black54,
                  ),
                  onPressed: onTogglePassword,
                )
              : null,
        ),
      ),
    );
  }
}
