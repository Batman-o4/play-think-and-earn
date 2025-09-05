import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillstreak/models/course.dart';
import 'package:skillstreak/services/user_service.dart';
import 'package:skillstreak/services/course_service.dart';
import 'package:skillstreak/screens/exercise_screen.dart';
import 'package:skillstreak/utils/app_theme.dart';

class CourseDetailScreen extends StatelessWidget {
  final Course course;

  const CourseDetailScreen({
    Key? key,
    required this.course,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(course.title),
      ),
      body: Consumer2<CourseService, UserService>(
        builder: (context, courseService, userService, child) {
          final progress = courseService.getCourseProgress(course.id);
          final progressPercent = progress?.progressPercent ?? 0;
          final isCompleted = progressPercent == 100;

          return Column(
            children: [
              // Course header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isCompleted 
                                ? AppTheme.successColor 
                                : AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isCompleted ? Icons.check_circle : Icons.school,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                course.description,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Course Progress',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$progressPercent%',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isCompleted 
                                    ? AppTheme.successColor 
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progressPercent / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted ? AppTheme.successColor : AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${progress?.completedExercises.length ?? 0} of ${course.exercises.length} exercises completed',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Exercises list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: course.exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = course.exercises[index];
                    final isCompleted = progress?.isExerciseCompleted(exercise.id) ?? false;
                    final isNext = !isCompleted && 
                        (index == 0 || (progress?.isExerciseCompleted(course.exercises[index - 1].id) ?? false));

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildExerciseCard(
                        context,
                        exercise,
                        index + 1,
                        isCompleted: isCompleted,
                        isNext: isNext,
                        isLocked: !isNext && !isCompleted,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    Exercise exercise,
    int number, {
    required bool isCompleted,
    required bool isNext,
    required bool isLocked,
  }) {
    return Card(
      opacity: isLocked ? 0.6 : 1.0,
      child: InkWell(
        onTap: (isCompleted || isNext) ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseScreen(
                courseId: course.id,
                exercise: exercise,
              ),
            ),
          );
        } : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Exercise number/status
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.successColor
                      : isNext
                          ? AppTheme.getExerciseColor(exercise.type)
                          : Colors.grey[400],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : isLocked
                          ? const Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 16,
                            )
                          : Text(
                              '$number',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Exercise info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exercise.displayName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isLocked ? AppTheme.textSecondary : null,
                            ),
                          ),
                        ),
                        // Exercise type icon
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.getExerciseColor(exercise.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getExerciseIcon(exercise.type),
                            size: 16,
                            color: AppTheme.getExerciseColor(exercise.type),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Difficulty and status
                    Row(
                      children: [
                        // Difficulty
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.getDifficultyColor(exercise.difficulty).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.getDifficultyColor(exercise.difficulty).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getDifficultyIcon(exercise.difficulty),
                                size: 12,
                                color: AppTheme.getDifficultyColor(exercise.difficulty),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getDifficultyText(exercise.difficulty),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.getDifficultyColor(exercise.difficulty),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        
                        // Status text
                        if (isCompleted)
                          const Text(
                            'Completed',
                            style: TextStyle(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          )
                        else if (isNext)
                          const Text(
                            'Ready to start',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          )
                        else
                          const Text(
                            'Locked',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow indicator
              if (isCompleted || isNext)
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getExerciseIcon(String exerciseType) {
    switch (exerciseType) {
      case 'trace':
        return Icons.gesture;
      case 'count':
        return Icons.visibility;
      case 'rhythm':
        return Icons.music_note;
      default:
        return Icons.play_arrow;
    }
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