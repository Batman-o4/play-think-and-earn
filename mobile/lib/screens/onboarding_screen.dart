import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _usernameController = TextEditingController();
  String _selectedAvatar = '👤';
  bool _isLoading = false;

  final List<String> _avatars = [
    '👤', '👨', '👩', '🧑', '👦', '👧', '👶', '👴', '👵',
    '🤖', '👽', '🎭', '🦸', '🧙', '🧚', '🧛', '🧜', '🧝'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // App Logo/Title
                const Icon(
                  Icons.school,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'SkillStreak',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gamified Micro-Learning',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                
                const Spacer(),
                
                // Username Input
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Let\'s get started!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Username Field
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Choose your username',
                          hintText: 'Enter a cool username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Avatar Selection
                      const Text(
                        'Pick your avatar:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _avatars.map((avatar) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedAvatar = avatar;
                              });
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _selectedAvatar == avatar
                                    ? const Color(0xFF667eea)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: _selectedAvatar == avatar
                                      ? const Color(0xFF667eea)
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  avatar,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Start Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _startApp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667eea),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Start Learning!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startApp() async {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a username'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user already exists
      final existingUser = await DatabaseService.instance.getUser(_usernameController.text.trim());
      
      if (existingUser != null) {
        // User exists, update last active date
        final updatedUser = existingUser.copyWith(
          lastActiveDate: DateTime.now(),
        );
        await DatabaseService.instance.updateUser(updatedUser);
      } else {
        // Create new user
        final newUser = User(
          username: _usernameController.text.trim(),
          avatar: _selectedAvatar,
          lastActiveDate: DateTime.now(),
        );
        await DatabaseService.instance.insertUser(newUser);
      }

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', _usernameController.text.trim());

      // Navigate to home screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}