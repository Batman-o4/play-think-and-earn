import 'package:flutter/material.dart';
import 'package:skillstreak/models/course.dart';
import 'package:skillstreak/models/exercise_run.dart';
import 'package:skillstreak/utils/app_theme.dart';

class TraceExerciseWidget extends StatefulWidget {
  final Exercise exercise;
  final Function(Map<String, dynamic>) onCompleted;

  const TraceExerciseWidget({
    Key? key,
    required this.exercise,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<TraceExerciseWidget> createState() => _TraceExerciseWidgetState();
}

class _TraceExerciseWidgetState extends State<TraceExerciseWidget> {
  final List<TracePoint> _tracePoints = [];
  final List<TracePoint> _templatePoints = [];
  DateTime? _startTime;
  bool _isTracing = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _generateTemplatePoints();
  }

  void _generateTemplatePoints() {
    // Generate template points based on the letter/word
    final data = widget.exercise.data;
    
    if (data['letter'] != null) {
      _generateLetterTemplate(data['letter'] as String);
    } else if (data['word'] != null) {
      _generateWordTemplate(data['word'] as String);
    } else {
      _generateDefaultTemplate();
    }
  }

  void _generateLetterTemplate(String letter) {
    // Simple template generation for letters
    // In a real app, you'd have proper letter templates
    final centerX = 200.0;
    final centerY = 200.0;
    final size = 100.0;
    
    switch (letter.toUpperCase()) {
      case 'A':
        _templatePoints.addAll([
          TracePoint(x: centerX - size/2, y: centerY + size/2, timestamp: 0),
          TracePoint(x: centerX, y: centerY - size/2, timestamp: 100),
          TracePoint(x: centerX + size/2, y: centerY + size/2, timestamp: 200),
          TracePoint(x: centerX - size/4, y: centerY, timestamp: 300),
          TracePoint(x: centerX + size/4, y: centerY, timestamp: 400),
        ]);
        break;
      case 'B':
        _templatePoints.addAll([
          TracePoint(x: centerX - size/2, y: centerY - size/2, timestamp: 0),
          TracePoint(x: centerX - size/2, y: centerY + size/2, timestamp: 100),
          TracePoint(x: centerX + size/4, y: centerY + size/2, timestamp: 200),
          TracePoint(x: centerX + size/2, y: centerY + size/4, timestamp: 300),
          TracePoint(x: centerX + size/4, y: centerY, timestamp: 400),
          TracePoint(x: centerX + size/2, y: centerY - size/4, timestamp: 500),
          TracePoint(x: centerX + size/4, y: centerY - size/2, timestamp: 600),
          TracePoint(x: centerX - size/2, y: centerY - size/2, timestamp: 700),
        ]);
        break;
      case 'C':
        _templatePoints.addAll([
          TracePoint(x: centerX + size/2, y: centerY - size/3, timestamp: 0),
          TracePoint(x: centerX + size/4, y: centerY - size/2, timestamp: 100),
          TracePoint(x: centerX - size/4, y: centerY - size/2, timestamp: 200),
          TracePoint(x: centerX - size/2, y: centerY - size/4, timestamp: 300),
          TracePoint(x: centerX - size/2, y: centerY + size/4, timestamp: 400),
          TracePoint(x: centerX - size/4, y: centerY + size/2, timestamp: 500),
          TracePoint(x: centerX + size/4, y: centerY + size/2, timestamp: 600),
          TracePoint(x: centerX + size/2, y: centerY + size/3, timestamp: 700),
        ]);
        break;
      default:
        _generateDefaultTemplate();
    }
  }

  void _generateWordTemplate(String word) {
    // Simple word template - just trace each letter
    final letterWidth = 80.0;
    final startX = 150.0 - (word.length * letterWidth / 2);
    
    for (int i = 0; i < word.length; i++) {
      final letterX = startX + (i * letterWidth);
      _templatePoints.addAll([
        TracePoint(x: letterX, y: 150, timestamp: i * 200),
        TracePoint(x: letterX, y: 250, timestamp: i * 200 + 100),
      ]);
    }
  }

  void _generateDefaultTemplate() {
    // Default simple shape
    final centerX = 200.0;
    final centerY = 200.0;
    final radius = 80.0;
    
    for (int i = 0; i < 20; i++) {
      final angle = (i / 20) * 2 * 3.14159;
      _templatePoints.add(TracePoint(
        x: centerX + radius * cos(angle),
        y: centerY + radius * sin(angle),
        timestamp: i * 50,
      ));
    }
  }

  double cos(double radians) => radians.cos();
  double sin(double radians) => radians.sin();

  void _onPanStart(DragStartDetails details) {
    if (_isCompleted) return;
    
    _startTime ??= DateTime.now();
    _isTracing = true;
    
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    _tracePoints.add(TracePoint(
      x: localPosition.dx,
      y: localPosition.dy,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
    
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isTracing || _isCompleted) return;
    
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    _tracePoints.add(TracePoint(
      x: localPosition.dx,
      y: localPosition.dy,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
    
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isTracing) return;
    
    _isTracing = false;
    
    // Check if trace is complete enough
    if (_tracePoints.length >= 10) {
      _completeExercise();
    }
  }

  void _completeExercise() {
    if (_isCompleted) return;
    
    _isCompleted = true;
    
    final timeSpent = _startTime != null 
        ? DateTime.now().difference(_startTime!).inMilliseconds
        : 0;
    
    final runData = {
      'tracePoints': _tracePoints.map((p) => p.toMap()).toList(),
      'templatePoints': _templatePoints.map((p) => p.toMap()).toList(),
      'timeSpent': timeSpent,
    };
    
    widget.onCompleted(runData);
  }

  void _resetTrace() {
    setState(() {
      _tracePoints.clear();
      _startTime = null;
      _isTracing = false;
      _isCompleted = false;
    });
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
                ? 'Great! You can submit your trace or try again.'
                : 'Trace the ${_getTraceTarget()} by following the dotted line with your finger.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
        
        // Canvas
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
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: TracePainter(
                    templatePoints: _templatePoints,
                    tracePoints: _tracePoints,
                    isCompleted: _isCompleted,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
        
        // Controls
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetTrace,
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 16),
              if (!_isCompleted)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _tracePoints.length >= 5 ? _completeExercise : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.traceColor,
                    ),
                    child: const Text('Finish Trace'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _getTraceTarget() {
    final data = widget.exercise.data;
    if (data['letter'] != null) {
      return 'letter ${data['letter']}';
    } else if (data['word'] != null) {
      return 'word "${data['word']}"';
    }
    return 'shape';
  }
}

class TracePainter extends CustomPainter {
  final List<TracePoint> templatePoints;
  final List<TracePoint> tracePoints;
  final bool isCompleted;

  TracePainter({
    required this.templatePoints,
    required this.tracePoints,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw template (dotted line)
    if (templatePoints.isNotEmpty) {
      final templatePaint = Paint()
        ..color = AppTheme.traceColor.withOpacity(0.5)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final templatePath = Path();
      templatePath.moveTo(templatePoints.first.x, templatePoints.first.y);
      
      for (int i = 1; i < templatePoints.length; i++) {
        templatePath.lineTo(templatePoints[i].x, templatePoints[i].y);
      }

      // Draw dotted line
      _drawDottedPath(canvas, templatePath, templatePaint);
    }

    // Draw user trace
    if (tracePoints.isNotEmpty) {
      final tracePaint = Paint()
        ..color = isCompleted ? AppTheme.successColor : AppTheme.traceColor
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final tracePath = Path();
      tracePath.moveTo(tracePoints.first.x, tracePoints.first.y);
      
      for (int i = 1; i < tracePoints.length; i++) {
        tracePath.lineTo(tracePoints[i].x, tracePoints[i].y);
      }

      canvas.drawPath(tracePath, tracePaint);
    }

    // Draw start point
    if (templatePoints.isNotEmpty) {
      final startPaint = Paint()
        ..color = AppTheme.successColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(templatePoints.first.x, templatePoints.first.y),
        8,
        startPaint,
      );

      // Draw arrow or "START" text
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'START',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          templatePoints.first.x - textPainter.width / 2,
          templatePoints.first.y - textPainter.height / 2,
        ),
      );
    }
  }

  void _drawDottedPath(Canvas canvas, Path path, Paint paint) {
    const double dashWidth = 8.0;
    const double dashSpace = 4.0;
    
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;
      
      while (distance < pathMetric.length) {
        final length = draw ? dashWidth : dashSpace;
        final nextDistance = distance + length;
        
        if (draw) {
          final extractPath = pathMetric.extractPath(
            distance,
            nextDistance > pathMetric.length ? pathMetric.length : nextDistance,
          );
          canvas.drawPath(extractPath, paint);
        }
        
        distance = nextDistance;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}