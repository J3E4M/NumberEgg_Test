// คลาสช่วยจัดการฐานข้อมูล SQLite (สำหรับ Todo ที่ไม่ได้ใช้)
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init(); // Singleton instance
  static Database? _database; // ตัวแปรเก็บ database

  DBHelper._init(); // Private constructor

  // ดึง database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('todo.db');
    return _database!;
  }

  // สร้าง database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // สร้างตาราง
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        isDone INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // เพิ่ม task
  Future<int> addTask(String title) async {
    final db = await instance.database;
    return await db.insert('tasks', {'title': title, 'isDone': 0});
  }

  // ดึงข้อมูล tasks ทั้งหมด
  Future<List<Map<String, dynamic>>> getTasks() async {
    final db = await instance.database;
    return await db.query('tasks');
  }

  // อัพเดทสถานะ task
  Future<int> updateTask(int index, int checked) async {
    final db = await instance.database;
    print('isDone $checked, id $index');
    return await db.update('tasks', {'isDone': checked }, where: 'id = ?',
        whereArgs: [index]);
  }
}

