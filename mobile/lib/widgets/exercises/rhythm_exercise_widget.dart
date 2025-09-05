import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:skillstreak/models/course.dart';
import 'package:skillstreak/models/exercise_run.dart';
import 'package:skillstreak/utils/app_theme.dart';

class RhythmExerciseWidget extends StatefulWidget {
  final Exercise exercise;
  final Function(Map<String, dynamic>) onCompleted;

  const RhythmExerciseWidget({
    Key? key,
    required this.exercise,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<RhythmExerciseWidget> createState() => _RhythmExerciseWidgetState();
}

class _RhythmExerciseWidgetState extends State<RhythmExerciseWidget>
    with TickerProviderStateMixin {
  late int _bpm;
  late List<int> _pattern;
  late int _beatInterval;
  
  Timer? _rhythmTimer;
  Timer? _exerciseTimer;
  late AnimationController _beatAnimationController;
  late AnimationController _tapAnimationController;
  
  List<RhythmTap> _userTaps = [];
  List<RhythmTap> _expectedTaps = [];
  int _currentBeat = 0;
  bool _isPlaying = false;
  bool _isCompleted = false;
  DateTime? _startTime;
  int _exerciseDuration = 0;

  @override
  void initState() {
    super.initState();
    _initializeExercise();
    _setupAnimations();
  }

  void _initializeExercise() {
    final data = widget.exercise.data;
    _bpm = data['bpm'] as int? ?? 60;
    _pattern = List<int>.from(data['pattern'] as List? ?? [1, 0, 1, 0]);
    _beatInterval = (60000 / _bpm).round(); // milliseconds per beat
    
    // Calculate exercise duration based on pattern and difficulty
    final patternRepeats = widget.exercise.difficulty * 2; // More repeats for harder exercises
    _exerciseDuration = _beatInterval * _pattern.length * patternRepeats;
    
    _generateExpectedTaps(patternRepeats);
  }

  void _generateExpectedTaps(int repeats) {
    _expectedTaps.clear();
    final startTime = DateTime.now().millisecondsSinceEpoch;
    
    for (int repeat = 0; repeat < repeats; repeat++) {
      for (int i = 0; i < _pattern.length; i++) {
        if (_pattern[i] == 1) {
          final tapTime = startTime + (repeat * _pattern.length + i) * _beatInterval;
          _expectedTaps.add(RhythmTap(
            timestamp: tapTime,
            isCorrect: false,
          ));
        }
      }
    }
  }

  void _setupAnimations() {
    _beatAnimationController = AnimationController(
      duration: Duration(milliseconds: _beatInterval),
      vsync: this,
    );
    
    _tapAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rhythmTimer?.cancel();
    _exerciseTimer?.cancel();
    _beatAnimationController.dispose();
    _tapAnimationController.dispose();
    super.dispose();
  }

  void _startExercise() {
    if (_isPlaying) return;
    
    setState(() {
      _isPlaying = true;
      _currentBeat = 0;
      _userTaps.clear();
      _startTime = DateTime.now();
    });
    
    // Start beat animation
    _beatAnimationController.repeat();
    
    // Start rhythm timer
    _rhythmTimer = Timer.periodic(Duration(milliseconds: _beatInterval), (timer) {
      if (_currentBeat < _pattern.length * widget.exercise.difficulty * 2) {
        setState(() {
          _currentBeat++;
        });
      }
    });
    
    // Start exercise timer
    _exerciseTimer = Timer(Duration(milliseconds: _exerciseDuration), () {
      _stopExercise();
    });
  }

  void _stopExercise() {
    if (!_isPlaying) return;
    
    setState(() {
      _isPlaying = false;
      _isCompleted = true;
    });
    
    _rhythmTimer?.cancel();
    _exerciseTimer?.cancel();
    _beatAnimationController.stop();
    
    _completeExercise();
  }

  void _completeExercise() {
    final runData = {
      'taps': _userTaps.map((tap) => tap.toMap()).toList(),
      'expectedTaps': _expectedTaps.map((tap) => tap.toMap()).toList(),
      'bpm': _bpm,
    };
    
    widget.onCompleted(runData);
  }

  void _onTap() {
    if (!_isPlaying) return;
    
    final tapTime = DateTime.now().millisecondsSinceEpoch;
    _userTaps.add(RhythmTap(timestamp: tapTime));
    
    _tapAnimationController.forward().then((_) {
      _tapAnimationController.reverse();
    });
    
    setState(() {});
  }

  void _resetExercise() {
    _rhythmTimer?.cancel();
    _exerciseTimer?.cancel();
    _beatAnimationController.stop();
    
    setState(() {
      _isPlaying = false;
      _isCompleted = false;
      _currentBeat = 0;
      _userTaps.clear();
      _startTime = null;
    });
    
    _generateExpectedTaps(widget.exercise.difficulty * 2);
  }

  bool _shouldHighlightBeat(int beatIndex) {
    if (!_isPlaying) return false;
    
    final patternIndex = beatIndex % _pattern.length;
    return _pattern[patternIndex] == 1 && beatIndex == _currentBeat;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Instructions
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                _isCompleted 
                    ? 'Exercise completed! You tapped ${_userTaps.length} times.'
                    : _isPlaying
                        ? 'Tap the button when you see it light up!'
                        : 'Tap along with the rhythm at $_bpm BPM',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Pattern: ${_pattern.map((b) => b == 1 ? '●' : '○').join(' ')}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        // Rhythm visualization
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // BPM display
                Text(
                  '$_bpm BPM',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.rhythmColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Beat pattern visualization
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pattern.length * 4, (index) {
                      final patternIndex = index % _pattern.length;
                      final shouldBeat = _pattern[patternIndex] == 1;
                      final isActive = _shouldHighlightBeat(index);
                      final isPast = _isPlaying && index < _currentBeat;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? AppTheme.rhythmColor
                              : isPast
                                  ? (shouldBeat ? AppTheme.rhythmColor.withOpacity(0.5) : Colors.grey[300])
                                  : (shouldBeat ? AppTheme.rhythmColor.withOpacity(0.3) : Colors.grey[200]),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Main tap button
                AnimatedBuilder(
                  animation: Listenable.merge([_beatAnimationController, _tapAnimationController]),
                  builder: (context, child) {
                    final beatScale = _isPlaying && _shouldHighlightBeat(_currentBeat)
                        ? 1.0 + (_beatAnimationController.value * 0.2)
                        : 1.0;
                    final tapScale = 1.0 + (_tapAnimationController.value * 0.1);
                    
                    return Transform.scale(
                      scale: beatScale * tapScale,
                      child: GestureDetector(
                        onTap: _onTap,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _shouldHighlightBeat(_currentBeat)
                                ? AppTheme.rhythmColor
                                : AppTheme.rhythmColor.withOpacity(0.3),
                            border: Border.all(
                              color: AppTheme.rhythmColor,
                              width: 3,
                            ),
                            boxShadow: _shouldHighlightBeat(_currentBeat)
                                ? [
                                    BoxShadow(
                                      color: AppTheme.rhythmColor.withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            Icons.music_note,
                            size: 48,
                            color: _shouldHighlightBeat(_currentBeat)
                                ? Colors.white
                                : AppTheme.rhythmColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // Tap count
                Text(
                  'Taps: ${_userTaps.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Controls
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (!_isPlaying && !_isCompleted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startExercise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.rhythmColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Start Rhythm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              
              if (_isPlaying)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _stopExercise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Stop Exercise',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _resetExercise,
                  child: const Text('Reset'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}