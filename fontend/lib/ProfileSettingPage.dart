import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'database/user_database.dart';
import 'models/user.dart' as app_user;
import 'services/profile_image_service.dart';
import 'config/supabase_config.dart';
import 'services/supabase_service.dart';

class ProfileSettingsPage extends StatefulWidget {
  final app_user.User currentUser;

  const ProfileSettingsPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  bool _showPasswordFields = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentUser.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// เลือกรูปภาพโปรไฟล์
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเลือกรูป: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ถ่ายรูปภาพโปรไฟล์
  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการถ่ายรูป: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// แสดง dialog เลือกรูปภาพ
  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกรูปภาพโปรไฟล์'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('ถ่ายรูป'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('เลือกจากแกลเลอรี'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );
  }

  /// บันทึกการเปลี่ยนแปลง
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String newName = widget.currentUser.name;
      debugPrint('🔍 พยายามอัพเดทโปรไฟล์ผู้ใช้ ID: ${widget.currentUser.id}');

      // ตรวจสอบว่าเชื่อมต่อ Supabase ได้หรือไม่
      if (SupabaseConfig.isConfigured) {
        try {
          // อัปเดตชื่อด้วย Supabase
          if (_nameController.text.trim() != widget.currentUser.name) {
            newName = _nameController.text.trim();
            await Supabase.instance.client
                .from('users')
                .update({'name': newName, 'updated_at': DateTime.now().toIso8601String()})
                .eq('id', widget.currentUser.id);
            debugPrint('✅ อัพเดทชื่อด้วย Supabase สำเร็จ');
          }

          // อัปเดตรหัสผ่าน (ถ้ามีการเปลี่ยน)
          if (_showPasswordFields && _newPasswordController.text.isNotEmpty) {
            // ตรวจสอบรหัสผ่านปัจจุบัน (ใน production ควรเข้ารหัส)
            if (_currentPasswordController.text != widget.currentUser.password) {
              throw Exception('รหัสผ่านปัจจุบันไม่ถูกต้อง');
            }

            await Supabase.instance.client
                .from('users')
                .update({'password': _newPasswordController.text, 'updated_at': DateTime.now().toIso8601String()})
                .eq('id', widget.currentUser.id);
            debugPrint('✅ อัพเดทรหัสผ่านด้วย Supabase สำเร็จ');
          }

        } catch (supabaseError) {
          debugPrint('❌ Supabase update failed: $supabaseError');
          // Fallback ไปใช้ UserDatabase แบบเก่า
          throw supabaseError;
        }
      } else {
        // ใช้ UserDatabase แบบเก่า (fallback)
        debugPrint('🔄 ใช้ UserDatabase แบบเก่า (fallback)');
        
        // อัปเดตชื่อ
        if (_nameController.text.trim() != widget.currentUser.name) {
          newName = _nameController.text.trim();
          await UserDatabase.updateUser(
            id: widget.currentUser.id,
            name: newName,
          );
        }

        // อัปเดตรหัสผ่าน (ถ้ามีการเปลี่ยน)
        if (_showPasswordFields && _newPasswordController.text.isNotEmpty) {
          // ตรวจสอบรหัสผ่านปัจจุบัน
          if (_currentPasswordController.text != widget.currentUser.password) {
            throw Exception('รหัสผ่านปัจจุบันไม่ถูกต้อง');
          }

          await UserDatabase.updateUser(
            id: widget.currentUser.id,
            password: _newPasswordController.text,
          );
        }
      }

      // จัดการรูปภาพ (ถ้ามีการเปลี่ยน)
      String? newImagePath = widget.currentUser.profileImagePath;
      if (_selectedImage != null) {
        try {
          // บันทึกรูปภาพใหม่
          newImagePath = await ProfileImageService.updateProfileImage(
              _selectedImage!,
              widget.currentUser.id,
              widget.currentUser.profileImagePath);
          debugPrint('✅ Profile image updated successfully: $newImagePath');
        } catch (e) {
          debugPrint('❌ Error updating profile image: $e');
          // ไม่ต้อง throw exception ให้ทำงานต่อได้
        }
      }

      // อัปเดต SharedPreferences ด้วยข้อมูลใหม่
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', newName);
      await prefs.setString('name', newName); // สำหรับ _loadProfile
      await prefs.setString(
          'user_profile_image', newImagePath ?? ''); // เพิ่ม path รูปภาพ

      debugPrint('✅ Updated SharedPreferences with new name: $newName');
      if (newImagePath != null) {
        debugPrint('✅ Updated SharedPreferences with profile image: $newImagePath');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อัปเดตโปรไฟล์เรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
          ),
        );

        // กลับไปหน้า ProfilePage พร้อมข้อมูลใหม่
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ Profile update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ตรวจสอบความแข็งแรงของรหัสผ่าน
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกรหัสผ่าน';
    }
    if (value.length < 6) {
      return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
    }
    return null;
  }

  /// ตรวจสอบการยืนยันรหัสผ่าน
  String? _validateConfirmPassword(String? value) {
    if (value != _newPasswordController.text) {
      return 'รหัสผ่านไม่ตรงกัน';
    }
    return _validatePassword(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16),
          ),
        ),
        title: const Text(
          'ตั้งค่าโปรไฟล์',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'บันทึก',
                    style: TextStyle(
                      color: Color(0xFFFFC107),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // รูปโปรไฟล์
              GestureDetector(
                onTap: _showImagePickerDialog,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFC107),
                          width: 3,
                        ),
                      ),
                      child: _selectedImage != null
                          ? ClipOval(
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : widget.currentUser.name.isNotEmpty
                              ? CircleAvatar(
                                  radius: 60,
                                  backgroundColor: const Color(0xFFFFC107),
                                  child: Text(
                                    widget.currentUser.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFC107),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'แตะเพื่อเปลี่ยนรูปโปรไฟล์',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // ชื่อผู้ใช้
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อผู้ใช้',
                  hintText: 'กรอกชื่อของคุณ',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFFC107)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกชื่อผู้ใช้';
                  }
                  if (value.trim().length < 2) {
                    return 'ชื่อผู้ใช้ต้องมีอย่างน้อย 2 ตัวอักษร';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ส่วนของรหัสผ่าน
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Header ของส่วนรหัสผ่าน
                    ListTile(
                      title: const Text(
                        'เปลี่ยนรหัสผ่าน',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Switch(
                        value: _showPasswordFields,
                        onChanged: (value) {
                          setState(() {
                            _showPasswordFields = value;
                            if (!value) {
                              _currentPasswordController.clear();
                              _newPasswordController.clear();
                              _confirmPasswordController.clear();
                            }
                          });
                        },
                        activeColor: const Color(0xFFFFC107),
                      ),
                    ),

                    // ฟิลด์รหัสผ่าน (แสดงเมื่อเปิดใช้งาน)
                    if (_showPasswordFields) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            // รหัสผ่านปัจจุบัน
                            TextFormField(
                              controller: _currentPasswordController,
                              obscureText: _obscureCurrentPassword,
                              decoration: InputDecoration(
                                labelText: 'รหัสผ่านปัจจุบัน',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscureCurrentPassword =
                                          !_obscureCurrentPassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscureCurrentPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: _showPasswordFields
                                  ? (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'กรุณากรอกรหัสผ่านปัจจุบัน';
                                      }
                                      if (value !=
                                          widget.currentUser.password) {
                                        return 'รหัสผ่านปัจจุบันไม่ถูกต้อง';
                                      }
                                      return null;
                                    }
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // รหัสผ่านใหม่
                            TextFormField(
                              controller: _newPasswordController,
                              obscureText: _obscureNewPassword,
                              decoration: InputDecoration(
                                labelText: 'รหัสผ่านใหม่',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscureNewPassword =
                                          !_obscureNewPassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscureNewPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: _showPasswordFields
                                  ? _validatePassword
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // ยืนยันรหัสผ่านใหม่
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'ยืนยันรหัสผ่านใหม่',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: _showPasswordFields
                                  ? _validateConfirmPassword
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // คำแนะนำรหัสผ่าน
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'คำแนะนำรหัสผ่าน:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '• ควรมีความยาวอย่างน้อย 6 ตัวอักษร\n• ควรประกอบด้วยตัวอักษรและตัวเลข\n• หลีกเลี่ยงการใช้ข้อมูลส่วนตัว',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ข้อมูลบัญชี (แสดงอย่างเดียว)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ข้อมูลบัญชี',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('อีเมล', widget.currentUser.email),
                    _buildInfoRow(
                        'ระดับสิทธิ์', widget.currentUser.privilegeNameDisplay),
                    _buildInfoRow('STATUS : ONLINE',_formatDate(widget.currentUser.createdAt),),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
