import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class EggDatabase {
  static final EggDatabase instance = EggDatabase._init();
  static Database? _database;

  EggDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('egg.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE egg_detection (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_name TEXT,
        width_cm REAL,
        height_cm REAL,
        grade INTEGER,
        confidence REAL,
        created_at TEXT
      )
    ''');
  }

  // ✅ ย้ายเข้ามาใน class
  Future<void> insertEgg({
    required String imageName,
    required double widthCm,
    required double heightCm,
    required int grade,
    required double confidence,
  }) async {
    final db = await database;

    await db.insert('egg_detection', {
      'image_name': imageName,
      'width_cm': widthCm,
      'height_cm': heightCm,
      'grade': grade,
      'confidence': confidence,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
