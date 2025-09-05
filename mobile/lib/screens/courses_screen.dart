import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillstreak/services/user_service.dart';
import 'package:skillstreak/services/course_service.dart';
import 'package:skillstreak/models/course.dart';
import 'package:skillstreak/screens/course_detail_screen.dart';
import 'package:skillstreak/utils/app_theme.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({Key? key}) : super(key: key);

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final courseService = context.read<CourseService>();
    await courseService.loadCourses();
    
    final userService = context.read<UserService>();
    if (userService.currentUser != null) {
      await courseService.loadUserProgress(userService.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Consumer2<CourseService, UserService>(
          builder: (context, courseService, userService, child) {
            if (courseService.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (courseService.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load courses',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      courseService.error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        courseService.clearError();
                        _loadData();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final courses = courseService.courses;
            if (courses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No courses available',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for new courses',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            final userXP = userService.totalXP;
            final unlockedCourses = courseService.getUnlockedCourses(userXP);
            final lockedCourses = courseService.getLockedCourses(userXP);

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Unlocked courses section
                if (unlockedCourses.isNotEmpty) ...[
                  Text(
                    'Available Courses',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...unlockedCourses.map((course) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildCourseCard(
                      context,
                      course,
                      courseService.getCourseProgress(course.id),
                      isLocked: false,
                    ),
                  )),
                ],

                // Locked courses section
                if (lockedCourses.isNotEmpty) ...[
                  if (unlockedCourses.isNotEmpty) const SizedBox(height: 24),
                  Text(
                    'Locked Courses',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Earn more XP to unlock these courses',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...lockedCourses.map((course) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildCourseCard(
                      context,
                      course,
                      null,
                      isLocked: true,
                    ),
                  )),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    Course course,
    CourseProgress? progress,
    {required bool isLocked}
  ) {
    final progressPercent = progress?.progressPercent ?? 0;
    final isCompleted = progressPercent == 100;

    return Card(
      opacity: isLocked ? 0.6 : 1.0,
      child: InkWell(
        onTap: isLocked ? null : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(course: course),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Course icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isLocked 
                          ? Colors.grey[400] 
                          : isCompleted
                              ? AppTheme.successColor
                              : AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isLocked 
                          ? Icons.lock
                          : isCompleted
                              ? Icons.check_circle
                              : Icons.school,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Course info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isLocked ? AppTheme.textSecondary : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status indicator
                  if (isLocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${course.unlockXP} XP',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    )
                  else if (isCompleted)
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.successColor,
                      size: 24,
                    ),
                ],
              ),
              
              if (!isLocked) ...[
                const SizedBox(height: 16),
                
                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$progressPercent%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Exercise types
                Wrap(
                  spacing: 8,
                  children: _getExerciseTypes(course.exercises).map((type) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.getExerciseColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.getExerciseColor(type).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getExerciseIcon(type),
                            size: 16,
                            color: AppTheme.getExerciseColor(type),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            type.capitalize(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getExerciseColor(type),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getExerciseTypes(List<Exercise> exercises) {
    final types = exercises.map((e) => e.type).toSet().toList();
    types.sort();
    return types;
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
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}