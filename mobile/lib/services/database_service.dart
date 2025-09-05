import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/run.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'skillstreak.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        avatar TEXT NOT NULL,
        totalXP INTEGER DEFAULT 0,
        currentStreak INTEGER DEFAULT 0,
        longestStreak INTEGER DEFAULT 0,
        lastActiveDate TEXT NOT NULL,
        walletPoints INTEGER DEFAULT 0,
        unlockedCourses TEXT DEFAULT '',
        unlockedThemes TEXT DEFAULT '',
        unlockedBadges TEXT DEFAULT ''
      )
    ''');

    // Runs table
    await db.execute('''
      CREATE TABLE runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exerciseType TEXT NOT NULL,
        exerciseId TEXT NOT NULL,
        runData TEXT NOT NULL,
        score REAL NOT NULL,
        xpEarned INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        validated INTEGER DEFAULT 0
      )
    ''');

    // Leaderboard table
    await db.execute('''
      CREATE TABLE leaderboard (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        avatar TEXT NOT NULL,
        totalXP INTEGER NOT NULL,
        currentStreak INTEGER NOT NULL,
        rank INTEGER NOT NULL,
        lastUpdated TEXT NOT NULL
      )
    ''');
  }

  Future<void> init() async {
    await database;
  }

  // User operations
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUser(String username) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users', orderBy: 'totalXP DESC');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  // Run operations
  Future<int> insertRun(Run run) async {
    final db = await database;
    return await db.insert('runs', run.toMap());
  }

  Future<List<Run>> getUserRuns(String username) async {
    final db = await database;
    final maps = await db.query(
      'runs',
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => Run.fromMap(map)).toList();
  }

  Future<List<Run>> getRunsByType(String exerciseType) async {
    final db = await database;
    final maps = await db.query(
      'runs',
      where: 'exerciseType = ?',
      whereArgs: [exerciseType],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => Run.fromMap(map)).toList();
  }

  // Leaderboard operations
  Future<void> updateLeaderboard(List<Map<String, dynamic>> entries) async {
    final db = await database;
    await db.delete('leaderboard');
    
    for (var entry in entries) {
      await db.insert('leaderboard', {
        'username': entry['username'],
        'avatar': entry['avatar'],
        'totalXP': entry['totalXP'],
        'currentStreak': entry['currentStreak'],
        'rank': entry['rank'],
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final db = await database;
    return await db.query('leaderboard', orderBy: 'rank ASC');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}