import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class SupabaseExampleScreen extends StatefulWidget {
  const SupabaseExampleScreen({super.key});

  @override
  State<SupabaseExampleScreen> createState() => _SupabaseExampleScreenState();
}

class _SupabaseExampleScreenState extends State<SupabaseExampleScreen> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> privileges = [];
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // ตรวจสอบการเชื่อมต่อ
      final isConnected = await SupabaseService.checkConnection();
      if (!isConnected) {
        throw Exception('ไม่สามารถเชื่อมต่อ Supabase ได้');
      }

      // ดึงข้อมูล
      final [usersData, privilegesData] = await Future.wait([
        SupabaseService.getUsers(),
        SupabaseService.getPrivileges(),
      ]);

      setState(() {
        users = usersData;
        privileges = privilegesData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> testLogin() async {
    try {
      final result = await SupabaseService.login(
        'admin@number.egg.com',
        'admin123',
      );
      
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เข้าสู่ระบบสำเร็จ: ${result['name']}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เข้าสู่ระบบล้มเหลว'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Test'),
        actions: [
          IconButton(
            onPressed: loadData,
            icon: const Icon(Icons.refresh),
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
                      // Test Login Button
                      ElevatedButton.icon(
                        onPressed: testLogin,
                        icon: const Icon(Icons.login),
                        label: const Text('ทดสอบ Login'),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Privileges Section
                      const Text(
                        'Privileges (${privileges.length})',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...privileges.map((privilege) => Card(
                        child: ListTile(
                          title: Text(privilege['name']),
                          subtitle: Text('Level: ${privilege['level']}'),
                          trailing: Text(privilege['description'] ?? ''),
                        ),
                      )),
                      
                      const SizedBox(height: 24),
                      
                      // Users Section
                      const Text(
                        'Users (${users.length})',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...users.map((user) => Card(
                        child: ListTile(
                          title: Text(user['name']),
                          subtitle: Text(user['email']),
                          trailing: Text(user['privileges']['name'] ?? 'No privilege'),
                        ),
                      )),
                    ],
                  ),
                ),
    );
  }
}
