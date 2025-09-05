import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:skillstreak/models/exercise_run.dart';
import 'package:skillstreak/models/course.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:3000/api';
  static const Duration _timeout = Duration(seconds: 30);

  final http.Client _client = http.Client();

  // Exercise validation endpoint
  Future<ApiResponse<ExerciseScore>> validateRun({
    required String userId,
    required String exerciseType,
    required String exerciseId,
    required Map<String, dynamic> runData,
    String? courseId,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/exercises/validateRun'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              'exerciseType': exerciseType,
              'exerciseId': exerciseId,
              'runData': runData,
              if (courseId != null) 'courseId': courseId,
            }),
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final scoreData = data['score'] as Map<String, dynamic>;
        final score = ExerciseScore(
          accuracy: (scoreData['accuracy'] as num).toDouble(),
          xp: scoreData['xp'] as int,
          multiplier: (scoreData['multiplier'] as num?)?.toDouble() ?? 1.0,
          details: Map<String, dynamic>.from(scoreData['details'] as Map? ?? {}),
        );
        
        return ApiResponse.success(score);
      } else {
        return ApiResponse.error(data['error'] as String? ?? 'Validation failed');
      }
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Get available courses
  Future<ApiResponse<List<Course>>> getCourses() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/courses'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final coursesJson = data['courses'] as List<dynamic>;
        final courses = coursesJson
            .map((courseData) => Course.fromMap(courseData as Map<String, dynamic>))
            .toList();
        
        return ApiResponse.success(courses);
      } else {
        return ApiResponse.error(data['error'] as String? ?? 'Failed to fetch courses');
      }
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Get specific course
  Future<ApiResponse<Course>> getCourse(String courseId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/courses/$courseId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final course = Course.fromMap(data['course'] as Map<String, dynamic>);
        return ApiResponse.success(course);
      } else {
        return ApiResponse.error(data['error'] as String? ?? 'Failed to fetch course');
      }
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Get course progress
  Future<ApiResponse<CourseProgress>> getCourseProgress(String courseId, String userId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/courses/$courseId/progress/$userId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final progressData = data['progress'] as Map<String, dynamic>;
        final progress = CourseProgress(
          courseId: courseId,
          userId: userId,
          completedExercises: List<String>.from(progressData['completedExercises'] as List),
          progressPercent: progressData['progressPercent'] as int,
          updatedAt: DateTime.now(),
        );
        
        return ApiResponse.success(progress);
      } else {
        return ApiResponse.error(data['error'] as String? ?? 'Failed to fetch progress');
      }
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Update course progress
  Future<ApiResponse<CourseProgress>> updateCourseProgress(
    String courseId,
    String userId,
    String exerciseId,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/courses/$courseId/progress/$userId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'exerciseId': exerciseId}),
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final progressData = data['progress'] as Map<String, dynamic>;
        final progress = CourseProgress(
          courseId: courseId,
          userId: userId,
          completedExercises: List<String>.from(progressData['completedExercises'] as List),
          progressPercent: progressData['progressPercent'] as int,
          updatedAt: DateTime.now(),
        );
        
        return ApiResponse.success(progress);
      } else {
        return ApiResponse.error(data['error'] as String? ?? 'Failed to update progress');
      }
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Get leaderboard
  Future<ApiResponse<List<LeaderboardEntry>>> getLeaderboard({int limit = 50}) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/leaderboard?limit=$limit'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final leaderboardJson = data['leaderboard'] as List<dynamic>;
        final leaderboard = leaderboardJson
            .map((entry) => LeaderboardEntry.fromMap(entry as Map<String, dynamic>))
            .toList();
        
        return ApiResponse.success(leaderboard);
      } else {
        return ApiResponse.error(data['error'] as String? ?? 'Failed to fetch leaderboard');
      }
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Get user's leaderboard position
  Future<ApiResponse<UserLeaderboardStats>> getUserLeaderboardStats(String userId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/leaderboard/$userId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final statsData = data['userStats'] as Map<String, dynamic>;
        final stats = UserLeaderboardStats.fromMap(statsData);
        return ApiResponse.success(stats);
      } else {
        return ApiResponse.error(data['error'] as String? ?? 'Failed to fetch user stats');
      }
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Get exercise history
  Future<ApiResponse<List<ExerciseRun>>> getExerciseHistory(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/exercises/history/$userId?limit=$limit&offset=$offset'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final historyJson = data['history'] as List<dynamic>;
        final history = historyJson
            .map((runData) => ExerciseRun.fromMap(runData as Map<String, dynamic>))
            .toList();
        
        return ApiResponse.success(history);
      } else {
        return ApiResponse.error(data['error'] as String? ?? 'Failed to fetch history');
      }
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Check if backend is available
  Future<bool> isBackendAvailable() async {
    try {
      final response = await _client
          .get(Uri.parse('${_baseUrl.replaceAll('/api', '')}/health'))
          .timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}

// API Response wrapper
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? error;

  ApiResponse._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse._(isSuccess: true, data: data);
  }

  factory ApiResponse.error(String error) {
    return ApiResponse._(isSuccess: false, error: error);
  }

  bool get hasError => !isSuccess;
}

// Leaderboard models
class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final int totalXP;
  final int currentStreak;
  final DateTime? lastActivity;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.totalXP,
    required this.currentStreak,
    this.lastActivity,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      rank: map['rank'] as int,
      userId: map['user_id'] as String,
      username: map['username'] as String,
      totalXP: map['total_xp'] as int,
      currentStreak: map['current_streak'] as int,
      lastActivity: map['last_activity'] != null
          ? DateTime.parse(map['last_activity'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'LeaderboardEntry(rank: $rank, username: $username, xp: $totalXP)';
  }
}

class UserLeaderboardStats {
  final String userId;
  final String username;
  final int totalXP;
  final int currentStreak;
  final int rank;
  final int totalUsers;
  final DateTime? lastActivity;

  UserLeaderboardStats({
    required this.userId,
    required this.username,
    required this.totalXP,
    required this.currentStreak,
    required this.rank,
    required this.totalUsers,
    this.lastActivity,
  });

  factory UserLeaderboardStats.fromMap(Map<String, dynamic> map) {
    return UserLeaderboardStats(
      userId: map['user_id'] as String,
      username: map['username'] as String,
      totalXP: map['total_xp'] as int,
      currentStreak: map['current_streak'] as int,
      rank: map['rank'] as int,
      totalUsers: map['totalUsers'] as int,
      lastActivity: map['last_activity'] != null
          ? DateTime.parse(map['last_activity'] as String)
          : null,
    );
  }

  double get percentile => ((totalUsers - rank + 1) / totalUsers) * 100;

  @override
  String toString() {
    return 'UserLeaderboardStats(rank: $rank/$totalUsers, xp: $totalXP)';
  }
}