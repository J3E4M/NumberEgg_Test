import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_bottom_nav.dart';
import 'ProfileSettingPage.dart';
import 'database/user_database.dart';
import 'models/user.dart';
import 'services/profile_image_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = '';
  String email = '';
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      // ดึงข้อมูล user ที่ login อยู่จาก SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      
      if (isLoggedIn) {
        final userId = prefs.getInt('user_id');
        final userName = prefs.getString('user_name') ?? '';
        final userEmail = prefs.getString('user_email') ?? '';
        final userPrivilege = prefs.getString('user_privilege') ?? '';
        final userProfileImage = prefs.getString('user_profile_image') ?? '';
        
        if (userId != null) {
          // สร้าง User object จากข้อมูลใน SharedPreferences
          setState(() {
            currentUser = User(
              id: userId,
              email: userEmail,
              password: '', // ไม่ต้องเก็บ password ใน local storage
              name: userName,
              privilegeId: 1, // ค่าเริ่มต้น
              createdAt: '',
              updatedAt: '',
              privilegeName: userPrivilege,
              privilegeLevel: 1,
              profileImagePath: userProfileImage.isNotEmpty ? userProfileImage : null, // เพิ่ม path รูปภาพ
            );
            name = userName;
            email = userEmail;
          });
          print('Loaded current user from SharedPreferences: $currentUser');
        }
      } else {
        print('No user is logged in');
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  /// ดึงรูปโปรไฟล์จาก storage
  ImageProvider? _getProfileImage() {
    if (currentUser?.profileImagePath != null && currentUser!.profileImagePath!.isNotEmpty) {
      final profileImage = ProfileImageService.getProfileImage(currentUser!.profileImagePath);
      if (profileImage != null) {
        return FileImage(profileImage);
      }
    }
    return null; // ใช้ default icon
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? 'FarmerEiei';
      email = prefs.getString('email') ?? 'farmer@number.egg.com';
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 📸 Floating Camera Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFC107),
        child: const Icon(Icons.camera_alt, color: Colors.black),
        onPressed: () {
          Navigator.pushNamed(context, '/camera');
        },
      ),

      // ⬇️ Bottom Navigation
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👤 Header
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: _getProfileImage(),
                        child: _getProfileImage() == null 
                            ? const Icon(Icons.person, size: 42, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade400,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () async {
                              print('Edit profile button pressed');
                              print('Current user: $currentUser');
                              if (currentUser != null) {
                                print('Navigating to ProfileSettingsPage');
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileSettingsPage(
                                      currentUser: currentUser!,
                                    ),
                                  ),
                                );
                                
                                // รีเฟรชข้อมูลถ้ามีการเปลี่ยนแปลง
                                if (result == true) {
                                  print('Profile updated, refreshing data...');
                                  await _loadCurrentUser();
                                  await _loadProfile();
                                }
                              } else {
                                print('Current user is null');
                              }
                            },
                            child: const Text(
                              'แก้ไขโปรไฟล์',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),

              const SizedBox(height: 20),

              // 🧾 Info Fields
              _infoField(
                label: 'ชื่อ (Name)',
                value: name,
                icon: Icons.person,
              ),
              const SizedBox(height: 16),

              _infoField(
                label: 'อีเมล (Email)',
                value: email,
                icon: Icons.mail_outline,
              ),
              const SizedBox(height: 16),

              _infoField(
                label: 'รหัสผ่าน (Password)',
                value: '************',
                icon: Icons.lock,
              ),

              const SizedBox(height: 32),


              // 🚪 Logout Button
              Center(
                child: SizedBox(
                  width: 200,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF44336),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout ,color: Colors.white),
                    label: const Text(
                      'ออกจากระบบ',
                      style: TextStyle(fontWeight: FontWeight.bold ,color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- INFO FIELD ----------
  Widget _infoField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE082),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Text(
                value,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }
}