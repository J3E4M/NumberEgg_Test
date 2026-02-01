import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseClient? _client;
  
  /// ดึง Supabase Client instance
  static SupabaseClient get client {
    if (_client == null) {
      if (!SupabaseConfig.isConfigured) {
        throw Exception('Supabase ยังไม่ได้ตั้งค่า กรุณาตั้งค่าใน supabase_config.dart');
      }
      _client = Supabase.instance.client;
    }
    return _client!;
  }
  
  /// ตรวจสอบสถานะการเชื่อมต่อ
  static Future<bool> checkConnection() async {
    try {
      final response = await client.from('privileges').select('count').count();
      return response.count != null;
    } catch (e) {
      debugPrint('Supabase connection error: $e');
      return false;
    }
  }
  
  /// ดึงข้อมูล privileges ทั้งหมด
  static Future<List<Map<String, dynamic>>> getPrivileges() async {
    try {
      final response = await client
          .from('privileges')
          .select('*')
          .order('level');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการดึงข้อมูล privileges: $e');
    }
  }
  
  /// ดึงข้อมูล users ทั้งหมดพร้อม privilege
  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await client
          .from('users')
          .select('''
            *,
            privileges (
              name,
              level
            )
          ''')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการดึงข้อมูล users: $e');
    }
  }
  
  /// สร้าง user ใหม่
  static Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String name,
    required int privilegeId,
  }) async {
    try {
      final response = await client
          .from('users')
          .insert({
            'email': email,
            'password': password, // ควรเข้ารหัสใน production
            'name': name,
            'privilege_id': privilegeId,
          })
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการสร้าง user: $e');
    }
  }
  
  /// ตรวจสอบการเข้าสู่ระบบ
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
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
          .eq('password', password) // ควรเข้ารหัสใน production
          .maybeSingle();
      
      return response;
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการเข้าสู่ระบบ: $e');
    }
  }
}
