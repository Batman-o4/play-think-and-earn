import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillstreak/services/user_service.dart';
import 'package:skillstreak/services/course_service.dart';
import 'package:skillstreak/screens/courses_screen.dart';
import 'package:skillstreak/screens/profile_screen.dart';
import 'package:skillstreak/screens/leaderboard_screen.dart';
import 'package:skillstreak/screens/exercise_screen.dart';
import 'package:skillstreak/utils/app_theme.dart';
import 'package:skillstreak/widgets/user_stats_card.dart';
import 'package:skillstreak/widgets/quick_play_card.dart';
import 'package:skillstreak/widgets/achievement_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userService = context.read<UserService>();
    final courseService = context.read<CourseService>();
    
    await Future.wait([
      courseService.loadCourses(),
      if (userService.currentUser != null)
        courseService.loadUserProgress(userService.currentUser!.id),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      const CoursesScreen(),
      const LeaderboardScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SkillStreak'),
        actions: [
          Consumer<UserService>(
            builder: (context, userService, child) {
              return IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  _showAchievementDialog(userService.checkAchievements());
                },
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message and user stats
              Consumer<UserService>(
                builder: (context, userService, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${userService.displayName}!',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      UserStatsCard(user: userService.currentUser),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Achievement banner (if any new achievements)
              Consumer<UserService>(
                builder: (context, userService, child) {
                  final achievements = userService.checkAchievements();
                  if (achievements.isNotEmpty) {
                    return Column(
                      children: [
                        AchievementBanner(
                          achievement: achievements.last,
                          onTap: () => _showAchievementDialog(achievements),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Quick Play section
              Text(
                'Quick Play',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: QuickPlayCard(
                      title: 'Trace',
                      icon: Icons.gesture,
                      color: AppTheme.traceColor,
                      onTap: () => _startQuickExercise('trace'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickPlayCard(
                      title: 'Count',
                      icon: Icons.visibility,
                      color: AppTheme.countColor,
                      onTap: () => _startQuickExercise('count'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickPlayCard(
                      title: 'Rhythm',
                      icon: Icons.music_note,
                      color: AppTheme.rhythmColor,
                      onTap: () => _startQuickExercise('rhythm'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Continue Learning section
              Consumer<CourseService>(
                builder: (context, courseService, child) {
                  if (courseService.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userService = context.watch<UserService>();
                  final unlockedCourses = courseService.getUnlockedCourses(
                    userService.totalXP,
                  );

                  if (unlockedCourses.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  // Find course with progress
                  final inProgressCourse = unlockedCourses.firstWhere(
                    (course) {
                      final progress = courseService.getCourseProgress(course.id);
                      return progress != null && 
                             progress.progressPercent > 0 && 
                             progress.progressPercent < 100;
                    },
                    orElse: () => unlockedCourses.first,
                  );

                  final nextExercise = courseService.getNextExercise(inProgressCourse.id);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Continue Learning',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: InkWell(
                          onTap: nextExercise != null
                              ? () => _startExercise(inProgressCourse.id, nextExercise)
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            inProgressCourse.title,
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            nextExercise?.displayName ?? 'Course completed!',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (nextExercise != null)
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.getExerciseColor(nextExercise.type),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          _getExerciseIcon(nextExercise.type),
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: (courseService.getCourseProgress(inProgressCourse.id)?.progressPercent ?? 0) / 100,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${courseService.getCourseProgress(inProgressCourse.id)?.progressPercent ?? 0}% Complete',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Recent Activity (placeholder)
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No recent activity',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete some exercises to see your progress here',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startQuickExercise(String exerciseType) {
    // Create a quick exercise based on type
    final courseService = context.read<CourseService>();
    final userService = context.read<UserService>();
    
    // Find an appropriate exercise from available courses
    final unlockedCourses = courseService.getUnlockedCourses(userService.totalXP);
    
    for (final course in unlockedCourses) {
      final exercise = course.exercises.firstWhere(
        (ex) => ex.type == exerciseType,
        orElse: () => course.exercises.first,
      );
      
      if (exercise.type == exerciseType) {
        _startExercise(course.id, exercise);
        return;
      }
    }

    // Fallback: show message that no exercises are available
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No $exerciseType exercises available yet'),
      ),
    );
  }

  void _startExercise(String courseId, dynamic exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseScreen(
          courseId: courseId,
          exercise: exercise,
        ),
      ),
    ).then((_) {
      // Reload data after exercise completion
      _loadData();
    });
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

  void _showAchievementDialog(List<Achievement> achievements) {
    if (achievements.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Achievements'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: achievements.map((achievement) {
            return ListTile(
              leading: const Icon(Icons.star, color: AppTheme.accentColor),
              title: Text(achievement.title),
              subtitle: Text(achievement.description),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }
}