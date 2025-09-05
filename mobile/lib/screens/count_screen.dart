import 'package:flutter/material.dart';
import '../models/run.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';

class CountScreen extends StatefulWidget {
  const CountScreen({super.key});

  @override
  State<CountScreen> createState() => _CountScreenState();
}

class _CountScreenState extends State<CountScreen> {
  final List<CountImage> _images = [
    CountImage(id: 'apples', emoji: '🍎', correctCount: 5),
    CountImage(id: 'balls', emoji: '⚽', correctCount: 8),
    CountImage(id: 'cars', emoji: '🚗', correctCount: 3),
    CountImage(id: 'stars', emoji: '⭐', correctCount: 12),
  ];

  CountImage _currentImage = CountImage(id: 'apples', emoji: '🍎', correctCount: 5);
  int _guessedCount = 0;
  double _score = 0.0;
  bool _isValidating = false;
  String _statusMessage = 'How many apples do you see?';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Count Objects'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Image Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF2196F3),
            ),
            child: Column(
              children: [
                Text(
                  _currentImage.emoji,
                  style: const TextStyle(fontSize: 120),
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
          
          // Count Input
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Number Input
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xFF2196F3), width: 3),
                    ),
                    child: Center(
                      child: Text(
                        _guessedCount.toString(),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Number Pad
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [1, 2, 3].map((number) => _buildNumberButton(number)).toList(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [4, 5, 6].map((number) => _buildNumberButton(number)).toList(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [7, 8, 9].map((number) => _buildNumberButton(number)).toList(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton('Clear', () => _clearCount()),
                          _buildNumberButton(0),
                          _buildActionButton('Back', () => _backspace()),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Image Selection
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Select an image:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _images.map((image) {
                    return GestureDetector(
                      onTap: () => _selectImage(image),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _currentImage.id == image.id
                              ? const Color(0xFF2196F3)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: _currentImage.id == image.id
                                ? const Color(0xFF2196F3)
                                : Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            image.emoji,
                            style: const TextStyle(fontSize: 24),
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
                        onPressed: _clearCount,
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
                        onPressed: _isValidating ? null : _validateCount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
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
                            : const Text('Check Answer'),
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

  Widget _buildNumberButton(int number) {
    return GestureDetector(
      onTap: () => _addDigit(number),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF2196F3),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            number.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[600],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _addDigit(int digit) {
    setState(() {
      _guessedCount = _guessedCount * 10 + digit;
      if (_guessedCount > 999) _guessedCount = 999;
    });
  }

  void _clearCount() {
    setState(() {
      _guessedCount = 0;
      _score = 0.0;
      _statusMessage = 'How many ${_currentImage.id} do you see?';
    });
  }

  void _backspace() {
    setState(() {
      _guessedCount = (_guessedCount / 10).floor();
    });
  }

  void _selectImage(CountImage image) {
    setState(() {
      _currentImage = image;
      _guessedCount = 0;
      _score = 0.0;
      _statusMessage = 'How many ${image.id} do you see?';
    });
  }

  Future<void> _validateCount() async {
    if (_guessedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a count!'),
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
      final countData = CountRunData(
        guessedCount: _guessedCount,
        imageId: _currentImage.id,
        boundingBoxes: [], // Not used in this simple version
      );

      final run = Run(
        exerciseType: 'count',
        exerciseId: 'count_${_currentImage.id}',
        runData: countData.toJson(),
        score: 0.0,
        xpEarned: 20,
        timestamp: DateTime.now(),
      );

      // Validate with backend
      final result = await ApiService.instance.validateRun(run);
      
      setState(() {
        _score = result['score']?.toDouble() ?? 0.0;
        _statusMessage = _score >= 70 
            ? 'Correct! Well done!'
            : _score >= 40 
                ? 'Close! The correct answer is ${_currentImage.correctCount}'
                : 'Try again! The correct answer is ${_currentImage.correctCount}';
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

class CountImage {
  final String id;
  final String emoji;
  final int correctCount;

  CountImage({
    required this.id,
    required this.emoji,
    required this.correctCount,
  });
}