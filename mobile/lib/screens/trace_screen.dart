import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import '../models/run.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';

class TraceScreen extends StatefulWidget {
  const TraceScreen({super.key});

  @override
  State<TraceScreen> createState() => _TraceScreenState();
}

class _TraceScreenState extends State<TraceScreen> {
  final List<Offset> _points = [];
  final List<String> _letters = ['A', 'B', 'C', 'D', 'E'];
  String _currentLetter = 'A';
  double _score = 0.0;
  bool _isDrawing = false;
  bool _isValidating = false;
  String _statusMessage = 'Draw the letter A';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trace Letters'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Letter Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF667eea),
            ),
            child: Column(
              children: [
                Text(
                  _currentLetter,
                  style: const TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                if (_score > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Score: ${_score.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Drawing Canvas
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: TracePainter(_points),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          
          // Controls
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Letter Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _letters.map((letter) {
                    return GestureDetector(
                      onTap: () => _selectLetter(letter),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _currentLetter == letter
                              ? const Color(0xFF667eea)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: _currentLetter == letter
                                ? const Color(0xFF667eea)
                                : Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _currentLetter == letter
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 20),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _clearCanvas,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isValidating ? null : _validateDrawing,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isValidating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Validate'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDrawing = true;
      _points.add(details.localPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDrawing) {
      setState(() {
        _points.add(details.localPosition);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDrawing = false;
    });
  }

  void _selectLetter(String letter) {
    setState(() {
      _currentLetter = letter;
      _points.clear();
      _score = 0.0;
      _statusMessage = 'Draw the letter $letter';
    });
  }

  void _clearCanvas() {
    setState(() {
      _points.clear();
      _score = 0.0;
      _statusMessage = 'Draw the letter $_currentLetter';
    });
  }

  Future<void> _validateDrawing() async {
    if (_points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please draw something first!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isValidating = true;
    });

    try {
      // Create run data
      final traceData = TraceRunData(
        points: _points,
        letter: _currentLetter,
        width: 300.0, // Canvas width
        height: 300.0, // Canvas height
      );

      final run = Run(
        exerciseType: 'trace',
        exerciseId: 'trace_${_currentLetter.toLowerCase()}',
        runData: traceData.toJson(),
        score: 0.0,
        xpEarned: 10,
        timestamp: DateTime.now(),
      );

      // Validate with backend
      final result = await ApiService.instance.validateRun(run);
      
      setState(() {
        _score = result['score']?.toDouble() ?? 0.0;
        _statusMessage = _score >= 70 
            ? 'Great job! Well done!'
            : _score >= 40 
                ? 'Good attempt! Try again!'
                : 'Keep practicing!';
      });

      // Save run to database
      final validatedRun = run.copyWith(
        score: _score,
        xpEarned: result['xpEarned'] ?? 0,
        validated: true,
      );
      
      await DatabaseService.instance.insertRun(validatedRun);

      // Show result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Score: ${_score.toStringAsFixed(1)}% - ${result['xpEarned'] ?? 0} XP earned!'),
          backgroundColor: _score >= 70 ? Colors.green : Colors.orange,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }
}

class TracePainter extends CustomPainter {
  final List<Offset> points;

  TracePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF667eea)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Draw points
    final pointPaint = Paint()
      ..color = const Color(0xFF667eea)
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(TracePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}