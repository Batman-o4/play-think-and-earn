import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/run.dart';
import '../models/course.dart';

class ApiService {
  static final ApiService instance = ApiService._init();
  static String? _overrideHost;
  static String get _defaultHost => Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://127.0.0.1:3000';
  static String get _host => _overrideHost ?? _defaultHost;
  static String get baseUrl => '$_host/api';

  ApiService._init();

  void init() {
    // Initialize API service
  }

  // Optional: allow overriding the host (e.g., when using a physical device)
  void setHost(String hostWithSchemeAndPort) {
    _overrideHost = hostWithSchemeAndPort.trim().replaceAll(RegExp(r"/+$"), '');
  }

  Future<Map<String, dynamic>> validateRun(Run run) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/validateRun'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(run.toMap()),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to validate run: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to local validation if backend is unavailable
      return _localValidateRun(run);
    }
  }

  Future<List<Course>> getCourses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/courses'));

      if (response.statusCode == 200) {
        final List<dynamic> coursesJson = jsonDecode(response.body);
        return coursesJson.map((json) => Course.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load courses: ${response.statusCode}');
      }
    } catch (e) {
      // Return default courses if backend is unavailable
      return _getDefaultCourses();
    }
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/leaderboard'));

      if (response.statusCode == 200) {
        final List<dynamic> leaderboardJson = jsonDecode(response.body);
        return leaderboardJson.map((json) => LeaderboardEntry.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load leaderboard: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  Future<void> updateLeaderboard(List<Map<String, dynamic>> entries) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/leaderboard'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(entries),
      );
    } catch (e) {
      // Silently fail if backend is unavailable
    }
  }

  Map<String, dynamic> _localValidateRun(Run run) {
    double score = 0.0;
    int xpEarned = 0;

    switch (run.exerciseType) {
      case 'trace':
        score = _validateTraceRun(run.runData);
        break;
      case 'count':
        score = _validateCountRun(run.runData);
        break;
      case 'rhythm':
        score = _validateRhythmRun(run.runData);
        break;
    }

    xpEarned = (score * run.xpEarned / 100).round();
    
    return {
      'validated': true,
      'score': score,
      'xpEarned': xpEarned,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  double _validateTraceRun(Map<String, dynamic> runData) {
    // Simple trace validation - compare drawn points to template
    final points = runData['points'] as List<dynamic>;
    final letter = runData['letter'] as String;
    
    if (points.isEmpty) return 0.0;
    
    // Basic validation: check if enough points were drawn
    final minPoints = _getMinPointsForLetter(letter);
    if (points.length < minPoints) return 0.0;
    
    // Simple scoring based on point count and letter complexity
    final baseScore = (points.length / minPoints).clamp(0.0, 1.0) * 100;
    return baseScore;
  }

  double _validateCountRun(Map<String, dynamic> runData) {
    final guessedCount = runData['guessedCount'] as int;
    final imageId = runData['imageId'] as String;
    
    // Get correct count for image (in real app, this would come from backend)
    final correctCount = _getCorrectCountForImage(imageId);
    
    if (guessedCount == correctCount) return 100.0;
    
    final difference = (guessedCount - correctCount).abs();
    final maxDifference = correctCount;
    
    return ((maxDifference - difference) / maxDifference * 100).clamp(0.0, 100.0);
  }

  double _validateRhythmRun(Map<String, dynamic> runData) {
    final tapTimes = List<int>.from(runData['tapTimes']);
    final expectedTimes = List<int>.from(runData['expectedTimes']);
    final bpm = runData['bpm'] as double;
    
    if (tapTimes.length != expectedTimes.length) return 0.0;
    
    double totalAccuracy = 0.0;
    final tolerance = (60000 / bpm * 0.1).round(); // 10% tolerance
    
    for (int i = 0; i < tapTimes.length; i++) {
      final difference = (tapTimes[i] - expectedTimes[i]).abs();
      final accuracy = (tolerance - difference) / tolerance;
      totalAccuracy += accuracy.clamp(0.0, 1.0);
    }
    
    return (totalAccuracy / tapTimes.length * 100).clamp(0.0, 100.0);
  }

  int _getMinPointsForLetter(String letter) {
    // Return minimum points needed for each letter
    switch (letter.toLowerCase()) {
      case 'a': return 8;
      case 'b': return 12;
      case 'c': return 6;
      case 'd': return 10;
      case 'e': return 8;
      default: return 6;
    }
  }

  int _getCorrectCountForImage(String imageId) {
    // Return correct count for each image
    switch (imageId) {
      case 'apples': return 5;
      case 'balls': return 8;
      case 'cars': return 3;
      case 'stars': return 12;
      default: return 1;
    }
  }

  List<Course> _getDefaultCourses() {
    return [
      Course(
        id: 'alphabet_basics',
        title: 'Alphabet Basics',
        description: 'Learn to trace basic letters',
        icon: '🔤',
        requiredXP: 0,
        exercises: [
          Exercise(
            id: 'trace_a',
            type: 'trace',
            title: 'Trace Letter A',
            description: 'Draw the letter A on the canvas',
            data: {'letter': 'A'},
            baseXP: 10,
          ),
          Exercise(
            id: 'trace_b',
            type: 'trace',
            title: 'Trace Letter B',
            description: 'Draw the letter B on the canvas',
            data: {'letter': 'B'},
            baseXP: 15,
          ),
        ],
      ),
      Course(
        id: 'counting_fun',
        title: 'Counting Fun',
        description: 'Practice counting objects',
        icon: '🔢',
        requiredXP: 50,
        exercises: [
          Exercise(
            id: 'count_apples',
            type: 'count',
            title: 'Count Apples',
            description: 'How many apples do you see?',
            data: {'imageId': 'apples'},
            baseXP: 20,
          ),
        ],
      ),
      Course(
        id: 'rhythm_master',
        title: 'Rhythm Master',
        description: 'Tap along with the beat',
        icon: '🎵',
        requiredXP: 100,
        exercises: [
          Exercise(
            id: 'rhythm_basic',
            type: 'rhythm',
            title: 'Basic Rhythm',
            description: 'Tap along with the basic beat',
            data: {'bpm': 120, 'pattern': [0, 500, 1000, 1500]},
            baseXP: 25,
          ),
        ],
      ),
    ];
  }
}