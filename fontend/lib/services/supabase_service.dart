import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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

  // ==================== EGG SESSION CRUD ====================

  /// สร้าง egg session ใหม่
  static Future<Map<String, dynamic>> createEggSession({
    required int userId,
    required String imagePath,
    required int eggCount,
    required double successPercent,
    required int bigCount,
    required int mediumCount,
    required int smallCount,
    required String day,
  }) async {
    try {
      final response = await client
          .from('egg_session')
          .insert({
            'user_id': userId,
            'image_path': imagePath,
            'egg_count': eggCount,
            'success_percent': successPercent,
            'big_count': bigCount,
            'medium_count': mediumCount,
            'small_count': smallCount,
            'day': day,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการสร้าง egg session: $e');
    }
  }

  /// สร้าง egg item ใหม่
  static Future<Map<String, dynamic>> createEggItem({
    required int sessionId,
    required int grade,
    required double confidence,
    double? x1,
    double? y1,
    double? x2,
    double? y2,
  }) async {
    try {
      final response = await client
          .from('egg_item')
          .insert({
            'session_id': sessionId,
            'grade': grade,
            'confidence': confidence,
            'x1': x1 ?? 0.0,
            'y1': y1 ?? 0.0,
            'x2': x2 ?? 0.0,
            'y2': y2 ?? 0.0,
          })
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการสร้าง egg item: $e');
    }
  }

  /// สร้าง egg session พร้อม egg items พร้อมกัน
  static Future<Map<String, dynamic>> createEggSessionWithItems({
    required int userId,
    required String imagePath,
    required int eggCount,
    required double successPercent,
    required int bigCount,
    required int mediumCount,
    required int smallCount,
    required String day,
    required List<Map<String, dynamic>> eggItems,
  }) async {
    try {
      // สร้าง session ก่อน
      final sessionResponse = await createEggSession(
        userId: userId,
        imagePath: imagePath,
        eggCount: eggCount,
        successPercent: successPercent,
        bigCount: bigCount,
        mediumCount: mediumCount,
        smallCount: smallCount,
        day: day,
      );

      // สร้าง egg items
      final itemsWithSessionId = eggItems.map((item) => {
        ...item,
        'session_id': sessionResponse['id'],
      }).toList();

      await client.from('egg_item').insert(itemsWithSessionId);

      return sessionResponse;
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการสร้าง egg session พร้อม items: $e');
    }
  }

  /// ดึงข้อมูล egg sessions ทั้งหมด
  static Future<List<Map<String, dynamic>>> getEggSessions() async {
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
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการดึงข้อมูล egg sessions: $e');
    }
  }

  /// ดึงข้อมูล egg sessions ตาม user_id
  static Future<List<Map<String, dynamic>>> getEggSessionsByUser(int userId) async {
    try {
      final response = await client
          .from('egg_session')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการดึงข้อมูล egg sessions ตาม user: $e');
    }
  }

  /// ดึงข้อมูล egg items ตาม session_id
  static Future<List<Map<String, dynamic>>> getEggItemsBySession(int sessionId) async {
    try {
      final response = await client
          .from('egg_item')
          .select('*')
          .eq('session_id', sessionId)
          .order('id', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการดึงข้อมูล egg items: $e');
    }
  }

  /// ดึงข้อมูลสถิติไข่ทั้งหมด
  static Future<Map<String, dynamic>> getEggStatistics() async {
    try {
      final response = await client
          .from('egg_session')
          .select('''
            egg_count,
            success_percent,
            big_count,
            medium_count,
            small_count
          ''');

      final sessions = List<Map<String, dynamic>>.from(response);
      
      if (sessions.isEmpty) {
        return {
          'total_sessions': 0,
          'total_eggs': 0,
          'total_big': 0,
          'total_medium': 0,
          'total_small': 0,
          'average_success_percent': 0.0,
        };
      }

      final totalSessions = sessions.length;
      final totalEggs = sessions.fold<int>(0, (sum, session) => sum + (session['egg_count'] as int? ?? 0));
      final totalBig = sessions.fold<int>(0, (sum, session) => sum + (session['big_count'] as int? ?? 0));
      final totalMedium = sessions.fold<int>(0, (sum, session) => sum + (session['medium_count'] as int? ?? 0));
      final totalSmall = sessions.fold<int>(0, (sum, session) => sum + (session['small_count'] as int? ?? 0));
      final avgSuccess = sessions.fold<double>(0, (sum, session) => sum + (session['success_percent'] as num? ?? 0)) / totalSessions;

      return {
        'total_sessions': totalSessions,
        'total_eggs': totalEggs,
        'total_big': totalBig,
        'total_medium': totalMedium,
        'total_small': totalSmall,
        'average_success_percent': double.parse(avgSuccess.toStringAsFixed(2)),
      };
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการดึงข้อมูลสถิติ: $e');
    }
  }

  // ==================== SYNC LOCAL TO SUPABASE ====================

  /// Sync ข้อมูล egg sessions และ items จาก local SQLite ขึ้น Supabase ทั้งหมด
  static Future<Map<String, dynamic>> syncLocalDataToSupabase() async {
    try {
      int syncedSessions = 0;
      int syncedItems = 0;
      int skippedSessions = 0;

      // ดึงข้อมูลจาก local SQLite
      final localSessions = await _getLocalSessions();
      
      for (final session in localSessions) {
        try {
          // ตรวจสอบว่า session นี้มีใน Supabase แล้วหรือไม่ (ตรวจสอบด้วย created_at + user_id)
          final existingSessions = await client
              .from('egg_session')
              .select('id')
              .eq('user_id', session['user_id'])
              .eq('created_at', session['created_at']);

          if (existingSessions.isNotEmpty) {
            skippedSessions++;
            continue; // ข้าม session ที่ sync ไปแล้ว
          }

          // สร้าง session ใหม่ใน Supabase
          final sessionResponse = await client
              .from('egg_session')
              .insert({
                'user_id': session['user_id'],
                'image_path': session['image_path'],
                'egg_count': session['egg_count'],
                'success_percent': session['success_percent'],
                'big_count': session['big_count'],
                'medium_count': session['medium_count'],
                'small_count': session['small_count'],
                'day': session['day'],
                'created_at': session['created_at'],
              })
              .select()
              .single();

          syncedSessions++;

          // ดึง egg items ของ session นี้จาก local
          final localItems = await _getLocalItemsBySession(session['id']);
          
          // สร้าง items ใน Supabase
          if (localItems.isNotEmpty) {
            final itemsForSupabase = localItems.map((item) => {
              'session_id': sessionResponse['id'],
              'grade': item['grade'],
              'confidence': item['confidence'],
              'x1': item['x1'] ?? 0.0,
              'y1': item['y1'] ?? 0.0,
              'x2': item['x2'] ?? 0.0,
              'y2': item['y2'] ?? 0.0,
            }).toList();

            await client.from('egg_item').insert(itemsForSupabase);
            syncedItems += itemsForSupabase.length;
          }
        } catch (e) {
          print('Error syncing session ${session['id']}: $e');
          continue;
        }
      }

      return {
        'synced_sessions': syncedSessions,
        'synced_items': syncedItems,
        'skipped_sessions': skippedSessions,
        'total_local_sessions': localSessions.length,
        'message': 'Sync completed successfully',
      };
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการ sync ข้อมูล: $e');
    }
  }

  /// ดึงข้อมูล sessions จาก local SQLite
  static Future<List<Map<String, dynamic>>> _getLocalSessions() async {
    try {
      // ต้อง import EggDatabase หรือใช้วิธีอื่นในการเข้าถึง local database
      final db = await openDatabase(
        join(await getDatabasesPath(), 'egg.db'),
      );
      
      final sessions = await db.query(
        'egg_session',
        orderBy: 'created_at ASC',
      );
      
      await db.close();
      return sessions;
    } catch (e) {
      print('Error getting local sessions: $e');
      return [];
    }
  }

  /// ดึงข้อมูล items ตาม session_id จาก local SQLite
  static Future<List<Map<String, dynamic>>> _getLocalItemsBySession(int sessionId) async {
    try {
      final db = await openDatabase(
        join(await getDatabasesPath(), 'egg.db'),
      );
      
      final items = await db.query(
        'egg_item',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'id ASC',
      );
      
      await db.close();
      return items;
    } catch (e) {
      print('Error getting local items for session $sessionId: $e');
      return [];
    }
  }
}
