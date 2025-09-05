import 'package:flutter/foundation.dart';
import 'package:skillstreak/models/course.dart';
import 'package:skillstreak/services/database_service.dart';
import 'package:skillstreak/services/api_service.dart';

class CourseService extends ChangeNotifier {
  final DatabaseService _databaseService;
  final ApiService _apiService;
  
  List<Course> _courses = [];
  Map<String, CourseProgress> _userProgress = {};
  bool _isLoading = false;
  String? _error;

  CourseService(this._databaseService, this._apiService);

  List<Course> get courses => _courses;
  Map<String, CourseProgress> get userProgress => _userProgress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCourses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to load from API first
      final apiResponse = await _apiService.getCourses();
      
      if (apiResponse.isSuccess && apiResponse.data != null) {
        _courses = apiResponse.data!;
        
        // Cache courses locally
        for (final course in _courses) {
          await _databaseService.insertCourse(course);
        }
      } else {
        // Fallback to local database
        _courses = await _databaseService.getAllCourses();
        
        if (_courses.isEmpty) {
          // If no courses in database, create default courses
          await _createDefaultCourses();
          _courses = await _databaseService.getAllCourses();
        }
      }
    } catch (e) {
      _error = 'Failed to load courses: ${e.toString()}';
      debugPrint(_error);
      
      // Try to load from local database as fallback
      try {
        _courses = await _databaseService.getAllCourses();
      } catch (localError) {
        debugPrint('Failed to load from local database: $localError');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUserProgress(String userId) async {
    try {
      final progressList = await _databaseService.getUserCourseProgress(userId);
      
      _userProgress = {
        for (final progress in progressList)
          progress.courseId: progress
      };
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load user progress: $e');
    }
  }

  Future<void> updateCourseProgress(
    String userId,
    String courseId,
    String exerciseId,
  ) async {
    try {
      // Get current progress
      CourseProgress? currentProgress = _userProgress[courseId];
      
      if (currentProgress == null) {
        currentProgress = CourseProgress(
          courseId: courseId,
          userId: userId,
          completedExercises: [],
          progressPercent: 0,
          updatedAt: DateTime.now(),
        );
      }

      // Add exercise if not already completed
      final updatedExercises = List<String>.from(currentProgress.completedExercises);
      if (!updatedExercises.contains(exerciseId)) {
        updatedExercises.add(exerciseId);
      }

      // Calculate progress percentage
      final course = getCourse(courseId);
      final totalExercises = course?.exercises.length ?? 1;
      final progressPercent = ((updatedExercises.length / totalExercises) * 100).round();

      final updatedProgress = currentProgress.copyWith(
        completedExercises: updatedExercises,
        progressPercent: progressPercent,
        updatedAt: DateTime.now(),
      );

      // Update local database
      await _databaseService.insertOrUpdateCourseProgress(updatedProgress);
      
      // Update API if available
      try {
        await _apiService.updateCourseProgress(courseId, userId, exerciseId);
      } catch (apiError) {
        debugPrint('Failed to sync progress with API: $apiError');
      }

      // Update local state
      _userProgress[courseId] = updatedProgress;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update course progress: $e');
    }
  }

  Course? getCourse(String courseId) {
    try {
      return _courses.firstWhere((course) => course.id == courseId);
    } catch (e) {
      return null;
    }
  }

  List<Course> getUnlockedCourses(int userXP) {
    return _courses.where((course) => course.isUnlocked(userXP)).toList();
  }

  List<Course> getLockedCourses(int userXP) {
    return _courses.where((course) => !course.isUnlocked(userXP)).toList();
  }

  CourseProgress? getCourseProgress(String courseId) {
    return _userProgress[courseId];
  }

  bool isExerciseCompleted(String courseId, String exerciseId) {
    final progress = _userProgress[courseId];
    return progress?.isExerciseCompleted(exerciseId) ?? false;
  }

  Exercise? getNextExercise(String courseId) {
    final course = getCourse(courseId);
    final progress = getCourseProgress(courseId);
    
    if (course == null) return null;

    // Find first uncompleted exercise
    for (final exercise in course.exercises) {
      if (progress?.isExerciseCompleted(exercise.id) != true) {
        return exercise;
      }
    }

    return null; // All exercises completed
  }

  List<Exercise> getCompletedExercises(String courseId) {
    final course = getCourse(courseId);
    final progress = getCourseProgress(courseId);
    
    if (course == null || progress == null) return [];

    return course.exercises
        .where((exercise) => progress.isExerciseCompleted(exercise.id))
        .toList();
  }

  List<Exercise> getRemainingExercises(String courseId) {
    final course = getCourse(courseId);
    final progress = getCourseProgress(courseId);
    
    if (course == null) return [];

    return course.exercises
        .where((exercise) => progress?.isExerciseCompleted(exercise.id) != true)
        .toList();
  }

  bool isCourseCompleted(String courseId) {
    final progress = getCourseProgress(courseId);
    return progress?.progressPercent == 100;
  }

  Future<void> _createDefaultCourses() async {
    final defaultCourses = [
      Course(
        id: 'basics-alphabet',
        title: 'Alphabet Basics',
        description: 'Learn to trace letters A-Z',
        unlockXP: 0,
        createdAt: DateTime.now(),
        exercises: [
          Exercise(
            id: 'trace-a',
            type: 'trace',
            difficulty: 1,
            data: {'letter': 'A'},
          ),
          Exercise(
            id: 'trace-b',
            type: 'trace',
            difficulty: 1,
            data: {'letter': 'B'},
          ),
          Exercise(
            id: 'trace-c',
            type: 'trace',
            difficulty: 1,
            data: {'letter': 'C'},
          ),
          Exercise(
            id: 'count-shapes-1',
            type: 'count',
            difficulty: 1,
            data: {'objects': 'circles', 'count': 3},
          ),
          Exercise(
            id: 'rhythm-basic-1',
            type: 'rhythm',
            difficulty: 1,
            data: {'bpm': 60, 'pattern': [1, 0, 1, 0]},
          ),
        ],
      ),
      Course(
        id: 'intermediate-words',
        title: 'Word Formation',
        description: 'Combine letters into simple words',
        unlockXP: 500,
        createdAt: DateTime.now(),
        exercises: [
          Exercise(
            id: 'trace-cat',
            type: 'trace',
            difficulty: 2,
            data: {'word': 'CAT'},
          ),
          Exercise(
            id: 'count-animals',
            type: 'count',
            difficulty: 2,
            data: {'objects': 'animals', 'count': 5},
          ),
          Exercise(
            id: 'rhythm-medium-1',
            type: 'rhythm',
            difficulty: 2,
            data: {'bpm': 80, 'pattern': [1, 0, 1, 1, 0, 1, 0, 0]},
          ),
        ],
      ),
      Course(
        id: 'advanced-patterns',
        title: 'Pattern Recognition',
        description: 'Complex patterns and rhythms',
        unlockXP: 1500,
        createdAt: DateTime.now(),
        exercises: [
          Exercise(
            id: 'trace-cursive',
            type: 'trace',
            difficulty: 3,
            data: {'style': 'cursive', 'word': 'Hello'},
          ),
          Exercise(
            id: 'count-complex',
            type: 'count',
            difficulty: 3,
            data: {'objects': 'mixed', 'count': 8},
          ),
          Exercise(
            id: 'rhythm-complex-1',
            type: 'rhythm',
            difficulty: 3,
            data: {'bpm': 120, 'pattern': [1, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0]},
          ),
        ],
      ),
    ];

    for (final course in defaultCourses) {
      await _databaseService.insertCourse(course);
    }
  }

  Future<void> syncWithAPI() async {
    try {
      final apiResponse = await _apiService.getCourses();
      
      if (apiResponse.isSuccess && apiResponse.data != null) {
        _courses = apiResponse.data!;
        
        // Update local database
        for (final course in _courses) {
          await _databaseService.insertCourse(course);
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to sync with API: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}