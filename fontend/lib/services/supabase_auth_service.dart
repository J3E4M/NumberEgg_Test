import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// 🔐 บริการจัดการ Authentication ขั้นสูง
class SupabaseAuthService {
  static final client = Supabase.instance.client;
  static Map<String, dynamic>? _currentUser;

  /// ดึงข้อมูลผู้ใช้ปัจจุบัน
  static Map<String, dynamic>? get currentUser => _currentUser;

  /// 📝 สมัครสมาชิกพร้อม validation
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required int privilegeId,
  }) async {
    try {
      // ตรวจสอบ email ซ้ำ
      final existingUser = await client
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();
      
      if (existingUser != null) {
        throw Exception('Email นี้มีผู้ใช้แล้ว');
      }

      // เข้ารหัส password (แบบง่าย - ควรใช้ bcrypt ใน production)
      final hashedPassword = _hashPassword(password);

      // สร้างผู้ใช้ใหม่
      final response = await client
          .from('users')
          .insert({
            'email': email,
            'password': hashedPassword,
            'name': name,
            'privilege_id': privilegeId,
          })
          .select('''
            *,
            privileges (
              name,
              level
            )
          ''')
          .single();

      _currentUser = response;
      return response;
    } catch (e) {
      throw Exception('สมัครสมาชิกล้มเหลว: $e');
    }
  }

  /// 🔐 เข้าสู่ระบบพร้อม validation
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final hashedPassword = _hashPassword(password);

      final response = await client
          .from('users')
          .select('''
            *,
            privileges (
              name,
              level
            )
          ''')
          .eq('email', email)
          .eq('password', hashedPassword)
          .maybeSingle();

      if (response == null) {
        throw Exception('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
      }

      _currentUser = response;
      return response;
    } catch (e) {
      throw Exception('เข้าสู่ระบบล้มเหลว: $e');
    }
  }

  /// 🚪 ออกจากระบบ
  static void logout() {
    _currentUser = null;
  }

  /// 🔄 อัพเดทโปรไฟล์
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? password,
  }) async {
    if (_currentUser == null) {
      throw Exception('กรุณาเข้าสู่ระบบก่อน');
    }

    try {
      final Map<String, dynamic> updateData = {};
      
      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (password != null) updateData['password'] = _hashPassword(password);
      
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await client
          .from('users')
          .update(updateData)
          .eq('id', _currentUser!['id'])
          .select('''
            *,
            privileges (
              name,
              level
            )
          ''')
          .single();

      _currentUser = response;
      return response;
    } catch (e) {
      throw Exception('อัพเดทโปรไฟล์ล้มเหลว: $e');
    }
  }

  /// 🗑️ ลบบัญชีผู้ใช้
  static Future<void> deleteAccount() async {
    if (_currentUser == null) {
      throw Exception('กรุณาเข้าสู่ระบบก่อน');
    }

    try {
      await client.from('users').delete().eq('id', _currentUser!['id']);
      logout();
    } catch (e) {
      throw Exception('ลบบัญชีล้มเหลว: $e');
    }
  }

  /// 🔍 ตรวจสอบว่า email ซ้ำหรือไม่
  static Future<bool> isEmailDuplicate(String email) async {
    try {
      final existingUser = await client
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();
      
      return existingUser != null;
    } catch (e) {
      return false;
    }
  }

  /// 🔐 เข้ารหัสรหัสผ่าน (แบบง่าย - ควรใช้ bcrypt ใน production)
  static String _hashPassword(String password) {
    // ใช้วิธีง่ายๆ สำหรับ demo - ใน production ควรใช้ bcrypt หรือ argon2
    return password.split('').reversed.join('') + '_hashed';
  }
}

/// 🎨 UI สำหรับ Authentication
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool isLogin = true;
  bool isLoading = false;
  int selectedPrivilege = 2; // Default to User

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        final user = await SupabaseAuthService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เข้าสู่ระบบสำเร็จ: ${user['name']}'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      } else {
        await SupabaseAuthService.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          privilegeId: selectedPrivilege,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สมัครสมาชิกสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        
        setState(() => isLogin = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'เข้าสู่ระบบ' : 'สมัครสมาชิก'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'อีเมล',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกอีเมล';
                  }
                  if (!value.contains('@')) {
                    return 'กรุณากรอกอีเมลให้ถูกต้อง';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Password field
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'รหัสผ่าน',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกรหัสผ่าน';
                  }
                  if (value.length < 6) {
                    return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Name field (register only)
              if (!isLogin) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกชื่อ';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Privilege selector (register only)
                DropdownButtonFormField<int>(
                  value: selectedPrivilege,
                  decoration: const InputDecoration(
                    labelText: 'สิทธิ์ผู้ใช้',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Admin')),
                    DropdownMenuItem(value: 2, child: Text('User')),
                    DropdownMenuItem(value: 3, child: Text('Guest')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedPrivilege = value!);
                  },
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isLogin ? 'เข้าสู่ระบบ' : 'สมัครสมาชิก'),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Toggle login/register
              TextButton(
                onPressed: () {
                  setState(() => isLogin = !isLogin);
                },
                child: Text(isLogin ? 'ยังไม่มีบัญชี? สมัครสมาชิก' : 'มีบัญชีแล้ว? เข้าสู่ระบบ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
