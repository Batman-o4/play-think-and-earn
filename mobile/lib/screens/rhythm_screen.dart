import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/run.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';

class RhythmScreen extends StatefulWidget {
  const RhythmScreen({super.key});

  @override
  State<RhythmScreen> createState() => _RhythmScreenState();
}

class _RhythmScreenState extends State<RhythmScreen> with TickerProviderStateMixin {
  late AnimationController _beatController;
  late AnimationController _tapController;
  late Animation<double> _beatAnimation;
  late Animation<double> _tapAnimation;

  final List<int> _tapTimes = [];
  final List<int> _expectedTimes = [];
  Timer? _beatTimer;
  bool _isPlaying = false;
  bool _isValidating = false;
  double _score = 0.0;
  String _statusMessage = 'Tap along with the beat!';
  int _currentBeat = 0;
  double _bpm = 120.0;
  int _totalBeats = 8;

  @override
  void initState() {
    super.initState();
    _beatController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _beatAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _beatController,
      curve: Curves.easeInOut,
    ));
    
    _tapAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _tapController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _beatController.dispose();
    _tapController.dispose();
    _beatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rhythm Tap'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Beat Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF9C27B0),
            ),
            child: Column(
              children: [
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: _beatAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isPlaying ? _beatAnimation.value : 1.0,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: _isPlaying ? Colors.white : Colors.white70,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.music_note,
                          size: 60,
                          color: Color(0xFF9C27B0),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'BPM: ${_bpm.round()}',
                  style: const TextStyle(
                    fontSize: 16,
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
          
          // Tap Area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tap Button
                  GestureDetector(
                    onTap: _isPlaying ? _onTap : null,
                    child: AnimatedBuilder(
                      animation: _tapAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _tapAnimation.value,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: _isPlaying 
                                  ? const Color(0xFF9C27B0)
                                  : Colors.grey[400],
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _isPlaying ? 'TAP!' : 'START',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Progress Indicator
                  if (_isPlaying) ...[
                    Text(
                      'Beat ${_currentBeat + 1} of $_totalBeats',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _currentBeat / _totalBeats,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Controls
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // BPM Slider
                Row(
                  children: [
                    const Text('BPM: '),
                    Expanded(
                      child: Slider(
                        value: _bpm,
                        min: 60,
                        max: 200,
                        divisions: 28,
                        label: _bpm.round().toString(),
                        onChanged: _isPlaying ? null : (value) {
                          setState(() {
                            _bpm = value;
                          });
                        },
                      ),
                    ),
                    Text('${_bpm.round()}'),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isPlaying ? null : _startRhythm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Start'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isPlaying ? _stopRhythm : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Stop'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _clearTaps,
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
                        onPressed: _isValidating ? null : _validateRhythm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9C27B0),
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

  void _onTap() {
    if (!_isPlaying) return;
    
    _tapController.forward().then((_) {
      _tapController.reverse();
    });
    
    setState(() {
      _tapTimes.add(DateTime.now().millisecondsSinceEpoch);
    });
  }

  void _startRhythm() {
    setState(() {
      _isPlaying = true;
      _currentBeat = 0;
      _tapTimes.clear();
      _expectedTimes.clear();
      _statusMessage = 'Tap along with the beat!';
    });

    // Generate expected beat times
    final beatInterval = (60000 / _bpm).round();
    final startTime = DateTime.now().millisecondsSinceEpoch;
    
    for (int i = 0; i < _totalBeats; i++) {
      _expectedTimes.add(startTime + (i * beatInterval));
    }

    // Start beat animation
    _beatController.repeat(reverse: true);
    
    // Start beat timer
    _beatTimer = Timer.periodic(Duration(milliseconds: beatInterval), (timer) {
      if (_currentBeat >= _totalBeats) {
        _stopRhythm();
        return;
      }
      
      setState(() {
        _currentBeat++;
      });
    });
  }

  void _stopRhythm() {
    setState(() {
      _isPlaying = false;
      _currentBeat = 0;
    });
    
    _beatController.stop();
    _beatTimer?.cancel();
    _beatTimer = null;
  }

  void _clearTaps() {
    setState(() {
      _tapTimes.clear();
      _expectedTimes.clear();
      _score = 0.0;
      _statusMessage = 'Tap along with the beat!';
    });
  }

  Future<void> _validateRhythm() async {
    if (_tapTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tap some beats first!'),
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
      final rhythmData = RhythmRunData(
        tapTimes: _tapTimes,
        expectedTimes: _expectedTimes,
        bpm: _bpm,
      );

      final run = Run(
        exerciseType: 'rhythm',
        exerciseId: 'rhythm_${_bpm.round()}bpm',
        runData: rhythmData.toJson(),
        score: 0.0,
        xpEarned: 25,
        timestamp: DateTime.now(),
      );

      // Validate with backend
      final result = await ApiService.instance.validateRun(run);
      
      setState(() {
        _score = result['score']?.toDouble() ?? 0.0;
        _statusMessage = _score >= 70 
            ? 'Excellent rhythm!'
            : _score >= 40 
                ? 'Good timing! Keep practicing!'
                : 'Try to match the beat better!';
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