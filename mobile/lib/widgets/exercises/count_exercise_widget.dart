import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:skillstreak/models/course.dart';
import 'package:skillstreak/utils/app_theme.dart';

class CountExerciseWidget extends StatefulWidget {
  final Exercise exercise;
  final Function(Map<String, dynamic>) onCompleted;

  const CountExerciseWidget({
    Key? key,
    required this.exercise,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<CountExerciseWidget> createState() => _CountExerciseWidgetState();
}

class _CountExerciseWidgetState extends State<CountExerciseWidget> {
  int _userCount = 0;
  int? _correctCount;
  List<CountObject> _objects = [];
  DateTime? _startTime;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _generateObjects();
    _startTime = DateTime.now();
  }

  void _generateObjects() {
    final data = widget.exercise.data;
    _correctCount = data['count'] as int? ?? 5;
    final objectType = data['objects'] as String? ?? 'circles';
    
    final random = math.Random();
    _objects.clear();
    
    // Generate the correct number of target objects
    for (int i = 0; i < _correctCount!; i++) {
      _objects.add(CountObject(
        x: 50 + random.nextDouble() * 250,
        y: 50 + random.nextDouble() * 300,
        type: objectType,
        isTarget: true,
        color: _getObjectColor(objectType),
        size: 20 + random.nextDouble() * 15,
      ));
    }
    
    // Add some distractor objects based on difficulty
    final difficulty = widget.exercise.difficulty;
    int distractorCount = 0;
    
    switch (difficulty) {
      case 1:
        distractorCount = 0; // Easy: no distractors
        break;
      case 2:
        distractorCount = 2; // Medium: few distractors
        break;
      case 3:
        distractorCount = 4; // Hard: more distractors
        break;
    }
    
    for (int i = 0; i < distractorCount; i++) {
      _objects.add(CountObject(
        x: 50 + random.nextDouble() * 250,
        y: 50 + random.nextDouble() * 300,
        type: _getDistractorType(objectType),
        isTarget: false,
        color: _getDistractorColor(objectType),
        size: 15 + random.nextDouble() * 10,
      ));
    }
    
    // Shuffle objects
    _objects.shuffle(random);
  }

  Color _getObjectColor(String objectType) {
    switch (objectType) {
      case 'circles':
        return AppTheme.countColor;
      case 'animals':
        return Colors.brown;
      case 'mixed':
        return AppTheme.primaryColor;
      default:
        return AppTheme.countColor;
    }
  }

  Color _getDistractorColor(String objectType) {
    switch (objectType) {
      case 'circles':
        return Colors.grey;
      case 'animals':
        return Colors.grey[600]!;
      case 'mixed':
        return Colors.grey[500]!;
      default:
        return Colors.grey;
    }
  }

  String _getDistractorType(String objectType) {
    switch (objectType) {
      case 'circles':
        return 'squares';
      case 'animals':
        return 'plants';
      case 'mixed':
        return 'shapes';
      default:
        return 'squares';
    }
  }

  void _incrementCount() {
    if (_isCompleted) return;
    
    setState(() {
      _userCount++;
    });
  }

  void _decrementCount() {
    if (_isCompleted || _userCount <= 0) return;
    
    setState(() {
      _userCount--;
    });
  }

  void _submitCount() {
    if (_isCompleted) return;
    
    _isCompleted = true;
    
    final timeSpent = _startTime != null 
        ? DateTime.now().difference(_startTime!).inMilliseconds
        : 0;
    
    final runData = {
      'userCount': _userCount,
      'correctCount': _correctCount!,
      'timeSpent': timeSpent,
    };
    
    widget.onCompleted(runData);
  }

  void _resetCount() {
    setState(() {
      _userCount = 0;
      _isCompleted = false;
      _startTime = DateTime.now();
    });
    _generateObjects();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Instructions
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _isCompleted 
                ? 'You counted $_userCount ${_getObjectTypeName()}. Correct answer: $_correctCount'
                : 'Count the number of ${_getObjectTypeName()} in the image below.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
        
        // Objects display area
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: CountObjectsPainter(
                  objects: _objects,
                  showAnswers: _isCompleted,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        
        // Counter controls
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Count display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.countColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.countColor),
                ),
                child: Text(
                  'Count: $_userCount',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.countColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Counter buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decrease button
                  ElevatedButton(
                    onPressed: _userCount > 0 && !_isCompleted ? _decrementCount : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                    ),
                    child: const Icon(
                      Icons.remove,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  
                  // Submit button
                  ElevatedButton(
                    onPressed: !_isCompleted ? _submitCount : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.countColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    child: Text(
                      _isCompleted ? 'Submitted' : 'Submit',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Increase button
                  ElevatedButton(
                    onPressed: !_isCompleted ? _incrementCount : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Reset button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _resetCount,
                  child: const Text('Try Again'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getObjectTypeName() {
    final objectType = widget.exercise.data['objects'] as String? ?? 'circles';
    switch (objectType) {
      case 'circles':
        return 'blue circles';
      case 'animals':
        return 'animals';
      case 'mixed':
        return 'blue objects';
      default:
        return 'objects';
    }
  }
}

class CountObject {
  final double x;
  final double y;
  final String type;
  final bool isTarget;
  final Color color;
  final double size;

  CountObject({
    required this.x,
    required this.y,
    required this.type,
    required this.isTarget,
    required this.color,
    required this.size,
  });
}

class CountObjectsPainter extends CustomPainter {
  final List<CountObject> objects;
  final bool showAnswers;

  CountObjectsPainter({
    required this.objects,
    required this.showAnswers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final object in objects) {
      final paint = Paint()
        ..color = showAnswers && object.isTarget 
            ? object.color.withOpacity(1.0)
            : showAnswers && !object.isTarget
                ? object.color.withOpacity(0.3)
                : object.color
        ..style = PaintingStyle.fill;

      // Draw border for target objects when showing answers
      if (showAnswers && object.isTarget) {
        final borderPaint = Paint()
          ..color = AppTheme.successColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        
        canvas.drawCircle(
          Offset(object.x, object.y),
          object.size + 3,
          borderPaint,
        );
      }

      // Draw the object
      switch (object.type) {
        case 'circles':
          canvas.drawCircle(
            Offset(object.x, object.y),
            object.size,
            paint,
          );
          break;
        case 'squares':
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(object.x, object.y),
              width: object.size * 2,
              height: object.size * 2,
            ),
            paint,
          );
          break;
        case 'animals':
          _drawAnimal(canvas, object.x, object.y, object.size, paint);
          break;
        case 'plants':
          _drawPlant(canvas, object.x, object.y, object.size, paint);
          break;
        case 'shapes':
        case 'mixed':
          // Draw various shapes
          final shapeType = (object.x + object.y).toInt() % 3;
          switch (shapeType) {
            case 0:
              canvas.drawCircle(Offset(object.x, object.y), object.size, paint);
              break;
            case 1:
              canvas.drawRect(
                Rect.fromCenter(
                  center: Offset(object.x, object.y),
                  width: object.size * 2,
                  height: object.size * 2,
                ),
                paint,
              );
              break;
            case 2:
              _drawTriangle(canvas, object.x, object.y, object.size, paint);
              break;
          }
          break;
      }
    }
  }

  void _drawAnimal(Canvas canvas, double x, double y, double size, Paint paint) {
    // Simple animal representation (circle with ears)
    canvas.drawCircle(Offset(x, y), size, paint);
    canvas.drawCircle(Offset(x - size * 0.6, y - size * 0.6), size * 0.4, paint);
    canvas.drawCircle(Offset(x + size * 0.6, y - size * 0.6), size * 0.4, paint);
  }

  void _drawPlant(Canvas canvas, double x, double y, double size, Paint paint) {
    // Simple plant representation (rectangle stem with circle top)
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(x, y + size * 0.5),
        width: size * 0.3,
        height: size,
      ),
      paint,
    );
    canvas.drawCircle(Offset(x, y - size * 0.3), size * 0.6, paint);
  }

  void _drawTriangle(Canvas canvas, double x, double y, double size, Paint paint) {
    final path = Path();
    path.moveTo(x, y - size);
    path.lineTo(x - size, y + size);
    path.lineTo(x + size, y + size);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}