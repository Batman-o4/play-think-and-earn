import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:skillstreak/models/user.dart';
import 'package:skillstreak/models/course.dart';
import 'package:skillstreak/models/exercise_run.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'skillstreak.db';
  static const int _databaseVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> initialize() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        avatar_path TEXT,
        total_xp INTEGER DEFAULT 0,
        current_streak INTEGER DEFAULT 0,
        last_activity TEXT,
        created_at TEXT NOT NULL,
        preferences TEXT DEFAULT '{}'
      )
    ''');

    // Courses table
    await db.execute('''
      CREATE TABLE courses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        unlock_xp INTEGER DEFAULT 0,
        exercises TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Course progress table
    await db.execute('''
      CREATE TABLE course_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        completed_exercises TEXT DEFAULT '[]',
        progress_percent INTEGER DEFAULT 0,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (course_id) REFERENCES courses (id),
        FOREIGN KEY (user_id) REFERENCES users (id),
        UNIQUE(course_id, user_id)
      )
    ''');

    // Exercise runs table
    await db.execute('''
      CREATE TABLE exercise_runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        exercise_type TEXT NOT NULL,
        course_id TEXT,
        exercise_id TEXT NOT NULL,
        run_data TEXT NOT NULL,
        score_data TEXT,
        completed_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Leaderboard table (local cache)
    await db.execute('''
      CREATE TABLE leaderboard (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        username TEXT NOT NULL,
        total_xp INTEGER NOT NULL,
        current_streak INTEGER NOT NULL,
        rank INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_users_total_xp ON users (total_xp DESC)');
    await db.execute('CREATE INDEX idx_exercise_runs_user_id ON exercise_runs (user_id)');
    await db.execute('CREATE INDEX idx_course_progress_user_id ON course_progress (user_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades here
    if (oldVersion < newVersion) {
      // Migration logic would go here
    }
  }

  // User operations
  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert(
      'users',
      {
        ...user.toMap(),
        'preferences': jsonEncode(user.preferences),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return User.fromMap({
      ...map,
      'preferences': jsonDecode(map['preferences'] as String? ?? '{}'),
    });
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update(
      'users',
      {
        ...user.toMap(),
        'preferences': jsonEncode(user.preferences),
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query(
      'users',
      orderBy: 'total_xp DESC, current_streak DESC',
    );

    return maps.map((map) => User.fromMap({
      ...map,
      'preferences': jsonDecode(map['preferences'] as String? ?? '{}'),
    })).toList();
  }

  // Course operations
  Future<void> insertCourse(Course course) async {
    final db = await database;
    await db.insert(
      'courses',
      {
        ...course.toMap(),
        'exercises': jsonEncode(course.exercises.map((e) => e.toMap()).toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Course?> getCourse(String courseId) async {
    final db = await database;
    final maps = await db.query(
      'courses',
      where: 'id = ?',
      whereArgs: [courseId],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    final exercisesJson = jsonDecode(map['exercises'] as String) as List;
    final exercises = exercisesJson
        .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
        .toList();

    return Course.fromMap({
      ...map,
      'exercises': exercises,
    });
  }

  Future<List<Course>> getAllCourses() async {
    final db = await database;
    final maps = await db.query(
      'courses',
      orderBy: 'unlock_xp ASC',
    );

    return maps.map((map) {
      final exercisesJson = jsonDecode(map['exercises'] as String) as List;
      final exercises = exercisesJson
          .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
          .toList();

      return Course.fromMap({
        ...map,
        'exercises': exercises,
      });
    }).toList();
  }

  // Course progress operations
  Future<void> insertOrUpdateCourseProgress(CourseProgress progress) async {
    final db = await database;
    await db.insert(
      'course_progress',
      {
        ...progress.toMap(),
        'completed_exercises': jsonEncode(progress.completedExercises),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<CourseProgress?> getCourseProgress(String userId, String courseId) async {
    final db = await database;
    final maps = await db.query(
      'course_progress',
      where: 'user_id = ? AND course_id = ?',
      whereArgs: [userId, courseId],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return CourseProgress.fromMap({
      ...map,
      'completed_exercises': jsonDecode(map['completed_exercises'] as String),
    });
  }

  Future<List<CourseProgress>> getUserCourseProgress(String userId) async {
    final db = await database;
    final maps = await db.query(
      'course_progress',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );

    return maps.map((map) => CourseProgress.fromMap({
      ...map,
      'completed_exercises': jsonDecode(map['completed_exercises'] as String),
    })).toList();
  }

  // Exercise run operations
  Future<int> insertExerciseRun(ExerciseRun run) async {
    final db = await database;
    return await db.insert(
      'exercise_runs',
      {
        ...run.toMap(),
        'run_data': jsonEncode(run.runData),
        'score_data': run.score != null ? jsonEncode(run.score!.toMap()) : null,
      },
    );
  }

  Future<List<ExerciseRun>> getUserExerciseRuns(
    String userId, {
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    final maps = await db.query(
      'exercise_runs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'completed_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => ExerciseRun.fromMap({
      ...map,
      'run_data': jsonDecode(map['run_data'] as String),
      'score_data': map['score_data'] != null 
          ? jsonDecode(map['score_data'] as String)
          : null,
    })).toList();
  }

  Future<List<ExerciseRun>> getExerciseRunsByType(
    String userId,
    String exerciseType, {
    int? limit,
  }) async {
    final db = await database;
    final maps = await db.query(
      'exercise_runs',
      where: 'user_id = ? AND exercise_type = ?',
      whereArgs: [userId, exerciseType],
      orderBy: 'completed_at DESC',
      limit: limit,
    );

    return maps.map((map) => ExerciseRun.fromMap({
      ...map,
      'run_data': jsonDecode(map['run_data'] as String),
      'score_data': map['score_data'] != null 
          ? jsonDecode(map['score_data'] as String)
          : null,
    })).toList();
  }

  // Statistics operations
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final db = await database;
    
    // Get basic user stats
    final userMaps = await db.query(
      'users',
      columns: ['total_xp', 'current_streak'],
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (userMaps.isEmpty) {
      return {
        'totalXP': 0,
        'currentStreak': 0,
        'totalRuns': 0,
        'averageScore': 0.0,
        'exerciseTypeStats': <String, dynamic>{},
      };
    }

    final user = userMaps.first;
    
    // Get exercise run stats
    final runStats = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_runs,
        AVG(CAST(JSON_EXTRACT(score_data, '\$.accuracy') AS REAL)) as avg_score,
        exercise_type,
        COUNT(exercise_type) as type_count
      FROM exercise_runs 
      WHERE user_id = ? AND score_data IS NOT NULL
      GROUP BY exercise_type
    ''', [userId]);

    final totalRunsResult = await db.rawQuery('''
      SELECT COUNT(*) as total_runs
      FROM exercise_runs 
      WHERE user_id = ?
    ''', [userId]);

    final totalRuns = totalRunsResult.first['total_runs'] as int;

    final exerciseTypeStats = <String, dynamic>{};
    double overallAvgScore = 0.0;
    int totalScoredRuns = 0;

    for (final stat in runStats) {
      final type = stat['exercise_type'] as String;
      final count = stat['type_count'] as int;
      final avgScore = stat['avg_score'] as double? ?? 0.0;
      
      exerciseTypeStats[type] = {
        'count': count,
        'averageScore': avgScore,
      };
      
      overallAvgScore += avgScore * count;
      totalScoredRuns += count;
    }

    if (totalScoredRuns > 0) {
      overallAvgScore /= totalScoredRuns;
    }

    return {
      'totalXP': user['total_xp'] as int,
      'currentStreak': user['current_streak'] as int,
      'totalRuns': totalRuns,
      'averageScore': overallAvgScore,
      'exerciseTypeStats': exerciseTypeStats,
    };
  }

  // Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('exercise_runs');
    await db.delete('course_progress');
    await db.delete('leaderboard');
    await db.delete('users');
    await db.delete('courses');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}