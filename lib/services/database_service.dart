import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/models/test_record.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'test_records.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE test_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        address TEXT NOT NULL,
        phone TEXT NOT NULL,
        testDate TEXT NOT NULL,
        overallScore REAL NOT NULL,
        status TEXT NOT NULL,
        categoryScores TEXT NOT NULL,
        strengths TEXT NOT NULL,
        weaknesses TEXT NOT NULL,
        advice TEXT NOT NULL,
        answers TEXT NOT NULL,
        questions TEXT NOT NULL
      )
    ''');
  }

  // ✅ insert new record
  Future<int> insertRecord(TestRecord record) async {
    Database db = await database;
    return await db.insert('test_records', record.toMap());
  }

  // ✅ get all records (sorted newest first)
  Future<List<TestRecord>> getAllRecords() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'test_records',
      orderBy: 'testDate DESC',
    );
    return List.generate(maps.length, (i) {
      return TestRecord.fromMap(maps[i]);
    });
  }

  // ✅ get records by name
  Future<List<TestRecord>> getRecordsByName(String name) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'test_records',
      where: 'name LIKE ?',
      whereArgs: ['%$name%'],
      orderBy: 'testDate DESC',
    );
    return List.generate(maps.length, (i) {
      return TestRecord.fromMap(maps[i]);
    });
  }

  // ✅ get record by id
  Future<TestRecord?> getRecordById(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'test_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return TestRecord.fromMap(maps.first);
    }
    return null;
  }

  // ✅ delete record
  Future<int> deleteRecord(int id) async {
    Database db = await database;
    return await db.delete(
      'test_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ✅ delete all records
  Future<void> deleteAllRecords() async {
    Database db = await database;
    await db.delete('test_records');
  }

  // ✅ record count
  Future<int> getRecordsCount() async {
    Database db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM test_records');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ✅ advanced search (between dates)
  Future<List<TestRecord>> getRecordsBetweenDates(
      DateTime startDate,
      DateTime endDate,
      ) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'test_records',
      where: 'testDate BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'testDate DESC',
    );
    return List.generate(maps.length, (i) {
      return TestRecord.fromMap(maps[i]);
    });
  }
}