import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database/user_database.dart';
import 'config/supabase_config.dart';
import 'services/supabase_service.dart';

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
  final _nameController = TextEditingController();

  final dio = Dio();
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  Future<void> register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || confirm.isEmpty || name.isEmpty) {
      setState(() => _errorMessage = 'กรุณากรอกข้อมูลให้ครบ');
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = 'รหัสผ่านไม่ตรงกัน');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔍 พยายามสมัครสมาชิก: $email');
      
      // ตรวจสอบว่าเชื่อมต่อ Supabase ได้หรือไม่
      if (!SupabaseConfig.isConfigured) {
        throw Exception('Supabase ยังไม่ได้ตั้งค่า');
      }
      
      // ตรวจสอบว่าอีเมลซ้ำหรือไม่
      try {
        final isEmailDuplicate = await SupabaseService.checkConnection();
        if (!isEmailDuplicate) {
          throw Exception('ไม่สามารถตรวจสอบการเชื่อมต่อได้');
        }
        
        // ตรวจสอบอีเมลซ้ำจริงๆ
        final existingUsers = await SupabaseService.getUsers();
        final emailExists = existingUsers.any((user) => user['email'] == email);
        
        if (emailExists) {
          setState(() => _errorMessage = 'อีเมลนี้ถูกใช้งานแล้ว');
          return;
        }
      } catch (emailError) {
        debugPrint('Email check failed, proceeding with registration: $emailError');
      }

      // สร้างผู้ใช้ใหม่ด้วย SupabaseService
      try {
        final result = await SupabaseService.createUser(
          email: email,
          password: password,
          name: name,
          privilegeId: 2, // User privilege
        );
        
        debugPrint('✅ สมัครสมาชิกสำเร็จ: ${result['name']}');
        
      } catch (createError) {
        debugPrint('❌ Supabase registration failed: $createError');
        
        // ถ้า Supabase ล้มเหลว ลอง fallback ไปใช้ UserDatabase แบบเก่า
        if (createError.toString().contains('Connection') || 
            createError.toString().contains('Network') ||
            createError.toString().contains('Supabase')) {
          
          debugPrint('🔄 ลอง fallback ไปใช้ UserDatabase แบบเก่า');
          
          try {
            final result = await UserDatabase.createUser(
              email: email,
              password: password,
              name: name,
              privilegeId: 2,
            );
            
            debugPrint('✅ Fallback registration successful: ${result['name']}');
            
          } catch (fallbackError) {
            debugPrint('❌ Fallback registration failed: $fallbackError');
            setState(() => _errorMessage = 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาลองใหม่ภายหลัง');
            return;
          }
        } else {
          setState(() => _errorMessage = 'เกิดข้อผิดพลาดในการสมัครสมาชิก: ${createError.toString()}');
          return;
        }
      }

      if (mounted) {
        // แสดง dialog สำเร็จ
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('สมัครสมาชิกสำเร็จ'),
            content: const Text('ยินดีต้อนรับสู่ระบบ Number Egg!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // ปิด dialog
                  Navigator.pushReplacementNamed(context, '/login'); // ไปหน้า login
                },
                child: const Text('ไปเข้าสู่ระบบ'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      setState(() => _errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

                /// 👤 NAME
                const Text('ชื่อ'),
                const SizedBox(height: 8),
                _inputField(
                  controller: _nameController,
                  icon: Icons.person,
                  hint: 'กรอกชื่อของคุณ',
                ),

                const SizedBox(height: 16),

                /// 🔒 PASSWORD
                const Text('Password'),
                const SizedBox(height: 8),
                _inputField(
                  controller: _passwordController,
                  icon: Icons.lock,
                  hint: '************',
                  obscure: _obscurePassword,
                  showPasswordToggle: true,
                  onTogglePassword: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),

                const SizedBox(height: 16),

                /// 🔒 CONFIRM
                const Text('Confirm Password'),
                const SizedBox(height: 8),
                _inputField(
                  controller: _confirmController,
                  icon: Icons.lock,
                  hint: '************',
                  obscure: _obscureConfirm,
                  showPasswordToggle: true,
                  onTogglePassword: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
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
                    onPressed: _isLoading ? null : register,
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
                              Text('กำลังสมัคร...'),
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

  Widget _inputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
    bool showPasswordToggle = false,
    VoidCallback? onTogglePassword,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
