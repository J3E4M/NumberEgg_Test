import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../services/supabase_service.dart';

class SupabaseFeaturesDemo extends StatefulWidget {
  const SupabaseFeaturesDemo({super.key});

  @override
  State<SupabaseFeaturesDemo> createState() => _SupabaseFeaturesDemoState();
}

class _SupabaseFeaturesDemoState extends State<SupabaseFeaturesDemo> {
  final client = Supabase.instance.client;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> privileges = [];
  List<Map<String, dynamic>> eggSessions = [];
  bool isLoading = false;
  String? error;
  Map<String, dynamic>? currentUser;

  @override
  void initState() {
    super.initState();
    loadData();
    setupRealtimeListener();
  }

  /// 🔥 Real-time Listener
  void setupRealtimeListener() {
    // ฟังการเปลี่ยนแปลงใน users table
    client.channel('users_changes').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'users',
      callback: (payload) {
        debugPrint('🔄 Users table changed: ${payload.eventType}');
        if (payload.eventType == PostgresChangeEvent.insert) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('มีผู้ใช้ใหม่: ${payload.newRecord?['name']}'),
              backgroundColor: Colors.green,
            ),
          );
        }
        loadData(); // โหลดข้อมูลใหม่
      },
    ).subscribe();

    // ฟังการเปลี่ยนแปลงใน egg_session table
    client.channel('egg_session_changes').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'egg_session',
      callback: (payload) {
        debugPrint('🥚 Egg session changed: ${payload.eventType}');
        loadData();
      },
    ).subscribe();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final [usersData, privilegesData, sessionsData] = await Future.wait([
        SupabaseService.getUsers(),
        SupabaseService.getPrivileges(),
        getEggSessions(),
      ]);

      setState(() {
        users = usersData;
        privileges = privilegesData;
        eggSessions = sessionsData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  /// 📊 ดึงข้อมูล egg sessions
  Future<List<Map<String, dynamic>>> getEggSessions() async {
    try {
      final response = await client
          .from('egg_session')
          .select('''
            *,
            users (
              name,
              email
            )
          ''')
          .order('created_at', ascending: false)
          .limit(10);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการดึงข้อมูล egg sessions: $e');
    }
  }

  /// 👤 สมัครสมาชิกใหม่
  Future<void> registerUser() async {
    try {
      final response = await SupabaseService.createUser(
        email: 'test${DateTime.now().millisecondsSinceEpoch}@email.com',
        password: 'password123',
        name: 'Test User ${DateTime.now().millisecondsSinceEpoch}',
        privilegeId: 2, // User privilege
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สมัครสมาชิกสำเร็จ: ${response['name']}'),
          backgroundColor: Colors.green,
        ),
      );
      
      loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สมัครสมาชิกล้มเหลว: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔐 Login
  Future<void> login() async {
    try {
      final result = await SupabaseService.login(
        'admin@number.egg.com',
        'admin123',
      );
      
      if (result != null) {
        setState(() {
          currentUser = result;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เข้าสู่ระบบสำเร็จ: ${result['name']}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เข้าสู่ระบบล้มเหลว: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🚪 Logout
  Future<void> logout() async {
    setState(() {
      currentUser = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ออกจากระบบแล้ว'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// 📤 อัพโหลดไฟล์ไป Supabase Storage
  Future<void> uploadFile() async {
    try {
      // สร้างข้อมูลตัวอย่าง
      final fileData = 'This is a test file content';
      final fileName = 'test_${DateTime.now().millisecondsSinceEpoch}.txt';
      
      // อัพโหลดไป Supabase Storage
      final response = await client.storage
          .from('egg-images')
          .uploadBinary(fileName, Uint8List.fromList(fileData.codeUnits));
      
      // ดึง public URL
      final publicUrl = client.storage
          .from('egg-images')
          .getPublicUrl(fileName);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัพโหลดไฟล์สำเร็จ: $publicUrl'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัพโหลดไฟล์ล้มเหลว: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📝 สร้าง egg session ใหม่
  Future<void> createEggSession() async {
    try {
      final response = await client
          .from('egg_session')
          .insert({
            'user_id': currentUser?['id'] ?? 1,
            'image_path': '/test/path/image.jpg',
            'egg_count': 10,
            'success_percent': 85.5,
            'grade0_count': 2,  // เบอร์ 0 (พิเศษ)
            'grade1_count': 2,  // เบอร์ 1 (ใหญ่)
            'grade2_count': 3,  // เบอร์ 2 (กลาง)
            'grade3_count': 2,  // เบอร์ 3 (เล็ก)
            'grade4_count': 1,  // เบอร์ 4 (เล็กมาก)
            'grade5_count': 0,  // เบอร์ 5 (พิเศษเล็ก)
            'day': DateTime.now().toString().split(' ')[0],
          })
          .select()
          .single();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สร้าง egg session สำเร็จ: ID ${response['id']}'),
          backgroundColor: Colors.green,
        ),
      );
      
      loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สร้าง egg session ล้มเหลว: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🗑️ ลบข้อมูล
  Future<void> deleteUser(int userId) async {
    try {
      await client.from('users').delete().eq('id', userId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบผู้ใช้สำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );
      
      loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ลบผู้ใช้ล้มเหลว: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentUser != null ? '👤 ${currentUser!['name']}' : 'Supabase Features Demo'),
        actions: [
          IconButton(
            onPressed: loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรชข้อมูล',
          ),
          if (currentUser != null)
            IconButton(
              onPressed: logout,
              icon: const Icon(Icons.logout),
              tooltip: 'ออกจากระบบ',
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('❌ $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: loadData,
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔐 Authentication Section
                      _buildSectionCard('🔐 Authentication', [
                        ElevatedButton.icon(
                          onPressed: currentUser == null ? login : null,
                          icon: const Icon(Icons.login),
                          label: const Text('Login (Admin)'),
                        ),
                        ElevatedButton.icon(
                          onPressed: registerUser,
                          icon: const Icon(Icons.person_add),
                          label: const Text('สมัครสมาชิกใหม่'),
                        ),
                      ]),
                      
                      const SizedBox(height: 16),
                      
                      // 📊 Database CRUD Section
                      _buildSectionCard('📊 Database CRUD', [
                        ElevatedButton.icon(
                          onPressed: createEggSession,
                          icon: const Icon(Icons.add),
                          label: const Text('สร้าง Egg Session'),
                        ),
                        ElevatedButton.icon(
                          onPressed: loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('โหลดข้อมูล'),
                        ),
                      ]),
                      
                      const SizedBox(height: 16),
                      
                      // 📤 File Storage Section
                      _buildSectionCard('📤 File Storage', [
                        ElevatedButton.icon(
                          onPressed: uploadFile,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('อัพโหลดไฟล์'),
                        ),
                      ]),
                      
                      const SizedBox(height: 16),
                      
                      // 🔄 Real-time Section
                      _buildSectionCard('🔄 Real-time Updates', [
                        const Text('กำลังฟังการเปลี่ยนแปลงแบบ real-time...'),
                        const Text('ลองเพิ่ม/แก้ไขข้อมูลใน Supabase Dashboard'),
                      ]),
                      
                      const SizedBox(height: 24),
                      
                      // 📋 Data Display
                      _buildDataDisplay(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: children,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Users
        _buildDataTable('👥 Users (${users.length})', users, (user) => [
          Text(user['name']),
          Text(user['email']),
          Text(user['privileges']['name'] ?? 'No privilege'),
          IconButton(
            onPressed: () => deleteUser(user['id']),
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ]),
        
        const SizedBox(height: 16),
        
        // Privileges
        _buildDataTable('🏆 Privileges (${privileges.length})', privileges, (privilege) => [
          Text(privilege['name']),
          Text('Level: ${privilege['level']}'),
          Text(privilege['description'] ?? ''),
        ]),
        
        const SizedBox(height: 16),
        
        // Egg Sessions
        _buildDataTable('🥚 Egg Sessions (${eggSessions.length})', eggSessions, (session) => [
          Text('ID: ${session['id']}'),
          Text('Eggs: ${session['egg_count']}'),
          Text('Success: ${session['success_percent']}%'),
          Text('User: ${session['users']['name']}'),
        ]),
      ],
    );
  }

  Widget _buildDataTable<T>(String title, List<T> data, List<Widget> Function(T) rowBuilder) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...data.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: rowBuilder(item),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
