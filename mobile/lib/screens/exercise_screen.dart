import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillstreak/models/course.dart';
import 'package:skillstreak/models/exercise_run.dart';
import 'package:skillstreak/services/user_service.dart';
import 'package:skillstreak/services/course_service.dart';
import 'package:skillstreak/services/api_service.dart';
import 'package:skillstreak/services/database_service.dart';
import 'package:skillstreak/widgets/exercises/trace_exercise_widget.dart';
import 'package:skillstreak/widgets/exercises/count_exercise_widget.dart';
import 'package:skillstreak/widgets/exercises/rhythm_exercise_widget.dart';
import 'package:skillstreak/screens/exercise_result_screen.dart';
import 'package:skillstreak/utils/app_theme.dart';

class ExerciseScreen extends StatefulWidget {
  final String courseId;
  final Exercise exercise;

  const ExerciseScreen({
    Key? key,
    required this.courseId,
    required this.exercise,
  }) : super(key: key);

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  bool _isSubmitting = false;
  Map<String, dynamic>? _runData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.displayName),
        backgroundColor: AppTheme.getExerciseColor(widget.exercise.type),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getDifficultyIcon(widget.exercise.difficulty),
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  _getDifficultyText(widget.exercise.difficulty),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Exercise description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: AppTheme.getExerciseColor(widget.exercise.type).withOpacity(0.1),
            child: Text(
              widget.exercise.description,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
          
          // Exercise widget
          Expanded(
            child: _buildExerciseWidget(),
          ),
          
          // Submit button
          if (_runData != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getExerciseColor(widget.exercise.type),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Exercise',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseWidget() {
    switch (widget.exercise.type) {
      case 'trace':
        return TraceExerciseWidget(
          exercise: widget.exercise,
          onCompleted: (runData) {
            setState(() {
              _runData = runData;
            });
          },
        );
      case 'count':
        return CountExerciseWidget(
          exercise: widget.exercise,
          onCompleted: (runData) {
            setState(() {
              _runData = runData;
            });
          },
        );
      case 'rhythm':
        return RhythmExerciseWidget(
          exercise: widget.exercise,
          onCompleted: (runData) {
            setState(() {
              _runData = runData;
            });
          },
        );
      default:
        return Center(
          child: Text(
            'Unknown exercise type: ${widget.exercise.type}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
    }
  }

  Future<void> _submitExercise() async {
    if (_runData == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userService = context.read<UserService>();
      final apiService = context.read<ApiService>();
      final databaseService = context.read<DatabaseService>();
      final courseService = context.read<CourseService>();

      if (userService.currentUser == null) {
        throw Exception('No user logged in');
      }

      // Create exercise run
      final exerciseRun = ExerciseRun(
        userId: userService.currentUser!.id,
        exerciseType: widget.exercise.type,
        courseId: widget.courseId,
        exerciseId: widget.exercise.id,
        runData: _runData!,
        completedAt: DateTime.now(),
      );

      // Try to validate with backend first
      ExerciseScore? score;
      try {
        final apiResponse = await apiService.validateRun(
          userId: userService.currentUser!.id,
          exerciseType: widget.exercise.type,
          exerciseId: widget.exercise.id,
          runData: _runData!,
          courseId: widget.courseId,
        );

        if (apiResponse.isSuccess) {
          score = apiResponse.data;
        }
      } catch (e) {
        debugPrint('API validation failed: $e');
      }

      // Fallback to local scoring if API failed
      if (score == null) {
        score = _calculateLocalScore(_runData!);
      }

      // Update exercise run with score
      final scoredRun = exerciseRun.copyWith(score: score);

      // Save to local database
      await databaseService.insertExerciseRun(scoredRun);

      // Update user stats
      await userService.addXP(score.xp);
      await userService.updateStreak();

      // Update course progress
      await courseService.updateCourseProgress(
        userService.currentUser!.id,
        widget.courseId,
        widget.exercise.id,
      );

      // Navigate to result screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseResultScreen(
              exercise: widget.exercise,
              exerciseRun: scoredRun,
              courseId: widget.courseId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit exercise: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  ExerciseScore _calculateLocalScore(Map<String, dynamic> runData) {
    // Simple local scoring fallback
    double accuracy = 50.0; // Default score
    
    switch (widget.exercise.type) {
      case 'trace':
        // Simple trace scoring based on completion
        accuracy = runData.containsKey('tracePoints') && 
                  (runData['tracePoints'] as List).isNotEmpty ? 75.0 : 25.0;
        break;
      case 'count':
        // Count scoring based on difference from correct answer
        final userCount = runData['userCount'] as int? ?? 0;
        final correctCount = runData['correctCount'] as int? ?? 0;
        final difference = (userCount - correctCount).abs();
        accuracy = difference == 0 ? 100.0 : 
                  difference == 1 ? 85.0 : 
                  difference <= 2 ? 70.0 : 50.0;
        break;
      case 'rhythm':
        // Rhythm scoring based on tap count
        final taps = runData['taps'] as List? ?? [];
        final expectedTaps = runData['expectedTaps'] as List? ?? [];
        if (expectedTaps.isNotEmpty) {
          final ratio = taps.length / expectedTaps.length;
          accuracy = ratio >= 0.8 && ratio <= 1.2 ? 80.0 : 60.0;
        }
        break;
    }

    final baseXP = 100;
    final xp = (accuracy * baseXP / 100).round();

    return ExerciseScore(
      accuracy: accuracy,
      xp: xp,
      multiplier: 1.0,
      details: {'localScoring': true},
    );
  }

  IconData _getDifficultyIcon(int difficulty) {
    switch (difficulty) {
      case 1:
        return Icons.circle;
      case 2:
        return Icons.square;
      case 3:
        return Icons.star;
      default:
        return Icons.help;
    }
  }

  String _getDifficultyText(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Easy';
      case 2:
        return 'Medium';
      case 3:
        return 'Hard';
      default:
        return 'Unknown';
    }
  }
}