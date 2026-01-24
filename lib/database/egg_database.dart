import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/egg_history.dart';

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
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'egg.db');

    return await openDatabase(
      path,
      version: 3, // ⭐ เพิ่ม version
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE egg_session (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      image_path TEXT NOT NULL,
      egg_count INTEGER NOT NULL,
      success_percent REAL NOT NULL,
      big_count INTEGER NOT NULL,
      medium_count INTEGER NOT NULL,
      small_count INTEGER NOT NULL,
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
  }

  // ✅ INSERT SESSION
  Future<int> insertSession({
    required String imagePath,
    required int eggCount,
    required double successPercent,
    required int bigCount,
    required int mediumCount,
    required int smallCount,
    required String day,
  }) async {
    final db = await database;

    final sessionId = await db.insert(
      'egg_session',
      {
        'image_path': imagePath,
        'egg_count': eggCount,
        'success_percent': successPercent,
        'big_count': bigCount,
        'medium_count': mediumCount,
        'small_count': smallCount,
        'day': day,
        'created_at': DateTime.now().toIso8601String(),
      },
    );

    return sessionId; // ⭐ สำคัญ
  }

  Future<void> insertEggItem({
    required int sessionId,
    required int grade,
    required double confidence,
  }) async {
    final db = await database;

    await db.insert(
      'egg_item',
      {
        'session_id': sessionId,
        'grade': grade,
        'confidence': confidence,
      },
    );
  }

  // ✅ READ HISTORY
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

      // ✅ สร้าง tags จาก DB จริง
      final List<String> tags = [];
      if ((row['big_count'] as int) > 0) {
        tags.add("${row['big_count']}xใหญ่");
      }
      if ((row['medium_count'] as int) > 0) {
        tags.add("${row['medium_count']}xกลาง");
      }
      if ((row['small_count'] as int) > 0) {
        tags.add("${row['small_count']}xเล็ก");
      }

      return {
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
      SUM(big_count) as big,
      SUM(medium_count) as medium,
      SUM(small_count) as small
    FROM egg_session
    WHERE day = ?
  ''', [today]);

    final row = result.first;

    return {
      'big': (row['big'] as int?) ?? 0,
      'medium': (row['medium'] as int?) ?? 0,
      'small': (row['small'] as int?) ?? 0,
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
      SUM(big_count) as big,
      SUM(medium_count) as medium,
      SUM(small_count) as small
    FROM egg_session
  ''');

    return result.first;
  }
}
