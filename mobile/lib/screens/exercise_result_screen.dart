import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillstreak/models/course.dart';
import 'package:skillstreak/models/exercise_run.dart';
import 'package:skillstreak/services/course_service.dart';
import 'package:skillstreak/utils/app_theme.dart';
import 'package:skillstreak/screens/exercise_screen.dart';

class ExerciseResultScreen extends StatelessWidget {
  final Exercise exercise;
  final ExerciseRun exerciseRun;
  final String courseId;

  const ExerciseResultScreen({
    Key? key,
    required this.exercise,
    required this.exerciseRun,
    required this.courseId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final score = exerciseRun.score;
    if (score == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exercise Complete')),
        body: const Center(
          child: Text('No score available'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Complete'),
        backgroundColor: AppTheme.getExerciseColor(exercise.type),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Score circle
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getScoreColor(score.accuracy),
                      boxShadow: [
                        BoxShadow(
                          color: _getScoreColor(score.accuracy).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${score.accuracy.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          score.grade,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Exercise title
                  Text(
                    exercise.displayName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Result message
                  Text(
                    _getResultMessage(score.accuracy),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Stats cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'XP Earned',
                          '${score.xp}',
                          Icons.star,
                          AppTheme.xpColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Accuracy',
                          '${score.accuracy.toStringAsFixed(0)}%',
                          Icons.target,
                          _getScoreColor(score.accuracy),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Multiplier',
                          '${score.multiplier.toStringAsFixed(1)}x',
                          Icons.trending_up,
                          AppTheme.streakColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Detailed feedback
                  if (score.details.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Details',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._buildDetailItems(context, score.details),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Action buttons
            Column(
              children: [
                // Next exercise button
                Consumer<CourseService>(
                  builder: (context, courseService, child) {
                    final nextExercise = courseService.getNextExercise(courseId);
                    
                    if (nextExercise != null) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExerciseScreen(
                                  courseId: courseId,
                                  exercise: nextExercise,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Next Exercise: ${nextExercise.displayName}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
                    
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 12),
                
                // Action buttons row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExerciseScreen(
                                courseId: courseId,
                                exercise: exercise,
                              ),
                            ),
                          );
                        },
                        child: const Text('Try Again'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('Back to Home'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDetailItems(BuildContext context, Map<String, dynamic> details) {
    final items = <Widget>[];
    
    details.forEach((key, value) {
      if (key == 'localScoring') return; // Skip internal flags
      
      String displayKey = key;
      String displayValue = value.toString();
      
      // Format specific keys
      switch (key) {
        case 'pathSimilarity':
          displayKey = 'Path Similarity';
          displayValue = '${(value as num).toStringAsFixed(1)}%';
          break;
        case 'coverage':
          displayKey = 'Coverage';
          displayValue = '${(value as num).toStringAsFixed(1)}%';
          break;
        case 'speedPenalty':
          displayKey = 'Speed Penalty';
          displayValue = '${(value as num).toStringAsFixed(1)}%';
          break;
        case 'timingAccuracy':
          displayKey = 'Timing Accuracy';
          displayValue = '${(value as num).toStringAsFixed(1)}%';
          break;
        case 'averageOffset':
          displayKey = 'Average Offset';
          displayValue = '${value}ms';
          break;
        case 'correctTaps':
          displayKey = 'Correct Taps';
          break;
        case 'missedTaps':
          displayKey = 'Missed Taps';
          break;
        case 'extraTaps':
          displayKey = 'Extra Taps';
          break;
        case 'timeSpent':
          displayKey = 'Time Spent';
          displayValue = '${(value as int / 1000).toStringAsFixed(1)}s';
          break;
      }
      
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayKey,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                displayValue,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    });
    
    return items;
  }

  Color _getScoreColor(double accuracy) {
    if (accuracy >= 90) return AppTheme.successColor;
    if (accuracy >= 70) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _getResultMessage(double accuracy) {
    if (accuracy >= 95) return 'Perfect! Outstanding work! 🌟';
    if (accuracy >= 90) return 'Excellent! You\'re doing great! 🎉';
    if (accuracy >= 80) return 'Great job! Keep it up! 👏';
    if (accuracy >= 70) return 'Good work! You\'re improving! 👍';
    if (accuracy >= 60) return 'Nice try! Practice makes perfect! 💪';
    return 'Keep practicing! You\'ll get better! 🚀';
  }
}