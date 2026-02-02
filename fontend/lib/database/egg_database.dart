import 'dart:developer'; // Add this line
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/egg_history.dart';
import '../utils/server_config.dart';

class EggDatabase {
  EggDatabase._();
  static final EggDatabase instance = EggDatabase._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    // For mobile, use default database factory
    // For web, we would need to use a different solution like Hive or SharedPreferences
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'egg.db');

    return await openDatabase(
      path,
      version: 7, // ⭐ เพิ่ม version สำหรับบังคับ migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE egg_session (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      image_path TEXT NOT NULL,
      egg_count INTEGER NOT NULL,
      success_percent REAL NOT NULL,
      grade0_count INTEGER NOT NULL,
      grade1_count INTEGER NOT NULL,
      grade2_count INTEGER NOT NULL,
      grade3_count INTEGER NOT NULL,
      grade4_count INTEGER NOT NULL,
      grade5_count INTEGER NOT NULL,
      day TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');

    await db.execute('''
    CREATE TABLE egg_item (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id INTEGER NOT NULL,
      grade INTEGER NOT NULL,
      confidence REAL NOT NULL,
      x1 REAL NOT NULL,
      y1 REAL NOT NULL,
      x2 REAL NOT NULL,
      y2 REAL NOT NULL,
      FOREIGN KEY (session_id) REFERENCES egg_session(id)
    )
  ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE egg_session ADD COLUMN big_count INTEGER NOT NULL DEFAULT 0');
      await db.execute(
          'ALTER TABLE egg_session ADD COLUMN medium_count INTEGER NOT NULL DEFAULT 0');
      await db.execute(
          'ALTER TABLE egg_session ADD COLUMN small_count INTEGER NOT NULL DEFAULT 0');

      await db.execute('''
      CREATE TABLE IF NOT EXISTS egg_item (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        grade INTEGER NOT NULL,
        confidence REAL NOT NULL,
        FOREIGN KEY (session_id) REFERENCES egg_session(id)
      )
    ''');
    }

    if (oldVersion < 5) {
      // Add user_id column to egg_session table
      await db.execute(
          'ALTER TABLE egg_session ADD COLUMN user_id INTEGER NOT NULL DEFAULT 1');
    }

    if (oldVersion < 6) {
      // Add new grade columns
      await db.execute(
          'ALTER TABLE egg_session ADD COLUMN grade0_count INTEGER NOT NULL DEFAULT 0');
      await db.execute(
          'ALTER TABLE egg_session ADD COLUMN grade1_count INTEGER NOT NULL DEFAULT 0');
      await db.execute(
          'ALTER TABLE egg_session ADD COLUMN grade2_count INTEGER NOT NULL DEFAULT 0');
      await db.execute(
          'ALTER TABLE egg_session ADD COLUMN grade3_count INTEGER NOT NULL DEFAULT 0');
      await db.execute(
          'ALTER TABLE egg_session ADD COLUMN grade4_count INTEGER NOT NULL DEFAULT 0');
      await db.execute(
          'ALTER TABLE egg_session ADD COLUMN grade5_count INTEGER NOT NULL DEFAULT 0');
      
      // Drop old columns if they exist (to avoid NOT NULL constraint conflicts)
      try {
        await db.execute('ALTER TABLE egg_session DROP COLUMN big_count');
        await db.execute('ALTER TABLE egg_session DROP COLUMN medium_count');
        await db.execute('ALTER TABLE egg_session DROP COLUMN small_count');
      } catch (e) {
        debugPrint('Columns already dropped or do not exist: $e');
      }
    }

    if (oldVersion < 7) {
      // Force clean migration - recreate table with correct schema
      await db.execute('DROP TABLE IF EXISTS egg_session_temp');
      
      await db.execute('''
      CREATE TABLE egg_session_temp AS 
      SELECT id, user_id, image_path, egg_count, success_percent,
             COALESCE(grade0_count, 0) as grade0_count,
             COALESCE(grade1_count, 0) as grade1_count,
             COALESCE(grade2_count, 0) as grade2_count,
             COALESCE(grade3_count, 0) as grade3_count,
             COALESCE(grade4_count, 0) as grade4_count,
             COALESCE(grade5_count, 0) as grade5_count,
             day, created_at
      FROM egg_session
      ''');
      
      await db.execute('DROP TABLE egg_session');
      await db.execute('ALTER TABLE egg_session_temp RENAME TO egg_session');
    }
  }

  // ✅ INSERT SESSION
  Future<int> insertSession({
    required int userId,
    required String imagePath,
    required int eggCount,
    required double successPercent,
    int grade0Count = 0,
    int grade1Count = 0,
    int grade2Count = 0,
    int grade3Count = 0,
    int grade4Count = 0,
    int grade5Count = 0,
    required String day,
  }) async {
    final db = await database;

    final sessionId = await db.insert(
      'egg_session',
      {
        'user_id': userId,
        'image_path': imagePath,
        'egg_count': eggCount,
        'success_percent': successPercent,
        'grade0_count': grade0Count,
        'grade1_count': grade1Count,
        'grade2_count': grade2Count,
        'grade3_count': grade3Count,
        'grade4_count': grade4Count,
        'grade5_count': grade5Count,
        'day': day,
        'created_at': DateTime.now().toIso8601String(),
      },
    );

    return sessionId;
  }

  // ================== EGG ITEM CRUD ==================

  Future<int> insertEggItem({
    required int sessionId,
    required int grade,
    required double confidence,
    double? x1,
    double? y1,
    double? x2,
    double? y2,
  }) async {
    final db = await database;
    return await db.insert('egg_item', {
      'session_id': sessionId,
      'grade': grade,
      'confidence': confidence,
      'x1': x1 ?? 0.0,
      'y1': y1 ?? 0.0,
      'x2': x2 ?? 0.0,
      'y2': y2 ?? 0.0,
    });
  }

  Future<List<Map<String, dynamic>>> getEggItemsBySession(int sessionId) async {
    final db = await database;
    return await db.query(
      'egg_item',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'id ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllEggItems() async {
    final db = await database;
    return await db.query('egg_item', orderBy: 'id DESC');
  }

  Future<int> updateEggItem(int id, {int? grade, double? confidence}) async {
    final db = await database;
    final Map<String, dynamic> data = {};
    if (grade != null) data['grade'] = grade;
    if (confidence != null) data['confidence'] = confidence;
    return await db.update('egg_item', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteEggItem(int id) async {
    final db = await database;
    return await db.delete('egg_item', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteEggItemsBySession(int sessionId) async {
    final db = await database;
    return await db
        .delete('egg_item', where: 'session_id = ?', whereArgs: [sessionId]);
  }

  // READ HISTORY
  Future<List<Map<String, dynamic>>> getHistory() async {
    final db = await database;
    return db.query(
      'egg_session',
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getHistoryForUI() async {
    final db = await database;
    final result = await db.query(
      'egg_session',
      orderBy: 'created_at DESC',
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return result.map((row) {
      final dayRaw = DateTime.parse(row['day'] as String);
      final targetDay = DateTime(dayRaw.year, dayRaw.month, dayRaw.day);

      final diff = today.difference(targetDay).inDays;

      String section;
      if (diff == 0) {
        section = 'TODAY';
      } else if (diff == 1) {
        section = 'YESTERDAY';
      } else if (diff <= 7) {
        section = 'LAST WEEK';
      } else {
        section = 'OLDER';
      }

      // ✅ สร้าง tags จาก DB จริง (มาตรฐานไทย)
      final List<String> tags = [];
      if ((row['grade0_count'] as int) > 0) {
        tags.add("${row['grade0_count']}xเบอร์ 0");
      }
      if ((row['grade1_count'] as int) > 0) {
        tags.add("${row['grade1_count']}xเบอร์ 1");
      }
      if ((row['grade2_count'] as int) > 0) {
        tags.add("${row['grade2_count']}xเบอร์ 2");
      }
      if ((row['grade3_count'] as int) > 0) {
        tags.add("${row['grade3_count']}xเบอร์ 3");
      }
      if ((row['grade4_count'] as int) > 0) {
        tags.add("${row['grade4_count']}xเบอร์ 4");
      }
      if ((row['grade5_count'] as int) > 0) {
        tags.add("${row['grade5_count']}xเบอร์ 5");
      }

      return {
        "sessionId": row['id'], // ✅ เพิ่ม session ID
        "section": section,
        "date": row['created_at'],
        "count": row['egg_count'],
        "isSuccess": (row['success_percent'] as num) >= 60,
        "tags": tags, // 🔥 ของจริงจาก DB
        "imagePath": row['image_path'],
      };
    }).toList();
  }

  Future<Map<String, int>> getTodayEggSummary() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final result = await db.rawQuery('''
    SELECT 
      SUM(grade0_count) as grade0,
      SUM(grade1_count) as grade1,
      SUM(grade2_count) as grade2,
      SUM(grade3_count) as grade3,
      SUM(grade4_count) as grade4,
      SUM(grade5_count) as grade5
    FROM egg_session 
    WHERE day = ?
  ''', [today]);

    final row = result.first;
    return {
      'เบอร์ 0': row['grade0'] as int? ?? 0,
      'เบอร์ 1': row['grade1'] as int? ?? 0,
      'เบอร์ 2': row['grade2'] as int? ?? 0,
      'เบอร์ 3': row['grade3'] as int? ?? 0,
      'เบอร์ 4': row['grade4'] as int? ?? 0,
      'เบอร์ 5': row['grade5'] as int? ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getWeeklyTrend() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT day, SUM(egg_count) AS total
    FROM egg_session
    GROUP BY day
    ORDER BY day ASC
    LIMIT 7
  ''');

    return result;
  }

  Future<Map<String, dynamic>> getSummaryReport() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT
      SUM(egg_count) as totalEgg,
      AVG(success_percent) as avgSuccess,
      SUM(grade0_count) as grade0,
      SUM(grade1_count) as grade1,
      SUM(grade2_count) as grade2,
      SUM(grade3_count) as grade3,
      SUM(grade4_count) as grade4,
      SUM(grade5_count) as grade5
    FROM egg_session
  ''');

    return result.first;
  }

  /// ลบข้อมูลไข่ทั้งหมด
  static Future<void> clearAllEggData() async {
    try {
      final baseUrl = await ServerConfig.getApiUrl();
      final response = await http.delete(
        Uri.parse('$baseUrl/egg/clear-all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        debugPrint('All egg data cleared successfully');
      } else {
        throw Exception('Failed to clear egg data: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error clearing egg data: $e');
    }
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('egg_session');
  }
}
