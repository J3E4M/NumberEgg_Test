import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/privilege.dart';

class UserDatabase {
  static const String baseUrl = 'http://192.168.1.186:8000';

  // ==================== PRIVILEGE CRUD ====================
  
  /// สร้าง privilege ใหม่
  static Future<Map<String, dynamic>> createPrivilege({
    required String name,
    String? description,
    int level = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/privileges'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'description': description,
          'level': level,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create privilege: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating privilege: $e');
    }
  }

  /// ดึงข้อมูล privileges ทั้งหมด
  static Future<List<Privilege>> getPrivileges() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/privileges'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> privilegesList = data['privileges'];
        return privilegesList.map((json) => Privilege.fromApiJson(json)).toList();
      } else {
        throw Exception('Failed to get privileges: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting privileges: $e');
    }
  }

  /// ดึงข้อมูล privilege ตาม id
  static Future<Privilege?> getPrivilegeById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/privileges/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Privilege.fromApiJson(data['privilege']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get privilege: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting privilege: $e');
    }
  }

  /// อัพเดทข้อมูล privilege
  static Future<bool> updatePrivilege({
    required int id,
    String? name,
    String? description,
    int? level,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (level != null) body['level'] = level;

      final response = await http.put(
        Uri.parse('$baseUrl/privileges/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update privilege: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating privilege: $e');
    }
  }

  /// ลบข้อมูล privilege
  static Future<bool> deletePrivilege(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/privileges/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete privilege: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting privilege: $e');
    }
  }

  /// ค้นหา privileges
  static Future<List<Privilege>> searchPrivileges(String keyword) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/privileges/search/$keyword'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> privilegesList = data['privileges'];
        return privilegesList.map((json) => Privilege.fromApiJson(json)).toList();
      } else {
        throw Exception('Failed to search privileges: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error searching privileges: $e');
    }
  }

  // ==================== USER CRUD ====================

  /// สร้าง user ใหม่
  static Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String name,
    required int privilegeId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, GET, PUT, DELETE',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
        body: {
          'email': email,
          'password': password,
          'name': name,
          'privilege_id': privilegeId.toString(),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  /// ดึงข้อมูล users ทั้งหมดพร้อม privilege
  static Future<List<User>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Debug: แสดงข้อมูลที่ server ส่งกลับมา
        if (kDebugMode) {
          print('GetUsers response data: $data');
        }
        
        List<User> usersList = [];
        
        if (data['users'] != null) {
          // กรณี server ส่งข้อมูลในรูปแบบ {"users": [...]}
          final usersData = data['users'];
          if (usersData is List) {
            usersList = usersData.map((json) => User.fromApiJson(json)).toList();
          } else if (usersData is Map) {
            // กรณี server ส่งข้อมูลเป็น Map เดียว
            usersList = [User.fromApiJson(usersData)];
          }
        } else if (data['id'] != null) {
          // กรณี server ส่งข้อมูล user เดียว
          usersList = [User.fromApiJson(data)];
        } else {
          // กรณี server ส่งข้อมูลเป็น array โดยตรง
          usersList = [User.fromApiJson(data)];
        }
        
        return usersList;
      } else {
        throw Exception('Failed to get users: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting users: $e');
    }
  }

  /// ดึงข้อมูล user ตาม id พร้อม privilege
  static Future<User?> getUserById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromApiJson(data['user']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting user: $e');
    }
  }

  /// อัพเดทข้อมูล user
  static Future<bool> updateUser({
    required int id,
    String? email,
    String? password,
    String? name,
    int? privilegeId,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (email != null) body['email'] = email;
      if (password != null) body['password'] = password;
      if (name != null) body['name'] = name;
      if (privilegeId != null) body['privilege_id'] = privilegeId;

      final response = await http.put(
        Uri.parse('$baseUrl/users/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  /// ลบข้อมูล user
  static Future<bool> deleteUser(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  

  /// ค้นหา users
  static Future<List<User>> searchUsers(String keyword) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/search/$keyword'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> usersList = data['users'];
        return usersList.map((json) => User.fromApiJson(json)).toList();
      } else {
        throw Exception('Failed to search users: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error searching users: $e');
    }
  }

  // ==================== AUTHENTICATION ====================

  /// ตรวจสอบการเข้าสู่ระบบ (Login)
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, GET, PUT, DELETE',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Debug: แสดงข้อมูลที่ server ส่งกลับมา
        if (kDebugMode) {
          print('Login response data: $data');
        }
        
        // ตรวจสอบรูปแบบข้อมูลที่ server ส่งกลับมา
        User user;
        if (data['user'] != null) {
          // กรณี server ส่งข้อมูลในรูปแบบ {user: {...}, privilege: ...}
          if (kDebugMode) {
            print('Using nested user format');
          }
          user = User.fromLoginJson(data);
        } else if (data['id'] != null) {
          // กรณี server ส่งข้อมูล user โดยตรง
          if (kDebugMode) {
            print('Using direct user format');
          }
          user = User(
            id: data['id'] as int,
            email: data['email'] as String,
            password: data['password'] as String,
            name: data['name'] as String,
            privilegeId: data['privilege_id'] as int,
            createdAt: data['created_at'] as String,
            updatedAt: data['updated_at'] as String,
            privilegeName: data['privilege_name'] as String?,
            privilegeLevel: data['privilege_level'] as int?,
            profileImagePath: data['profile_image_path'] as String?,
          );
        } else {
          // กรณี server ส่งข้อมูลในรูปแบบ array (จาก database)
          if (kDebugMode) {
            print('Using array format from database');
          }
          user = User.fromApiJson([
            data['id'],
            data['email'],
            data['password'],
            data['name'],
            data['privilege_id'],
            data['created_at'],
            data['updated_at'],
            data['privilege_name'],
            data['privilege_level'],
          ]);
        }
        
        return {
          'user': user,
          'privilege': data['privilege'] ?? data['privilege_name'] ?? 'User',
          'message': data['message'] ?? 'Login successful'
        };
      } else if (response.statusCode == 401) {
        if (kDebugMode) {
          print('Login failed: Invalid credentials');
        }
        return null; // ไม่พบผู้ใช้หรือรหัสผิด
      } else {
        if (kDebugMode) {
          print('Login failed: ${response.statusCode} - ${response.body}');
        }
        throw Exception('Server returned status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during login: $e');
    }
  }

  /// ตรวจสอบว่า email ซ้ำหรือไม่
  static Future<bool> isEmailDuplicate(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/check-email'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'email': email,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] ?? false;
      } else {
        // ถ้าไม่มี endpoint check-email ให้ใช้วิธีเก่า
        final users = await getUsers();
        return users.any((user) => user.email == email);
      }
    } catch (e) {
      // ถ้าเชื่อมต่อล้มเหลือให้ใช้วิธีเก่า
      try {
        final users = await getUsers();
        return users.any((user) => user.email == email);
      } catch (e2) {
        return false; // ถ้าไม่สามารถตรวจสอบได้ ให้สมมติว่าไม่ซ้ำ
      }
    }
  }

  // ==================== DATABASE STATUS ====================

  /// ตรวจสอบสถานะฐานข้อมูล
  static Future<Map<String, dynamic>> getDatabaseStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/db/status'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get database status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting database status: $e');
    }
  }
}
