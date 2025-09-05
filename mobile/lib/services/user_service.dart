import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:skillstreak/models/user.dart';
import 'package:skillstreak/services/database_service.dart';

class UserService extends ChangeNotifier {
  final DatabaseService _databaseService;
  User? _currentUser;
  bool _isLoading = false;

  UserService(this._databaseService);

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('current_user_id');

      if (currentUserId != null) {
        _currentUser = await _databaseService.getUser(currentUserId);
        
        // Update last activity if user exists
        if (_currentUser != null) {
          await updateLastActivity();
        }
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<User> createUser({
    required String username,
    String? avatarPath,
  }) async {
    final uuid = const Uuid();
    final user = User(
      id: uuid.v4(),
      username: username,
      avatarPath: avatarPath,
      createdAt: DateTime.now(),
    );

    await _databaseService.insertUser(user);
    
    // Save as current user
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', user.id);
    
    _currentUser = user;
    notifyListeners();

    return user;
  }

  Future<void> updateUser(User user) async {
    await _databaseService.updateUser(user);
    
    if (_currentUser?.id == user.id) {
      _currentUser = user;
      notifyListeners();
    }
  }

  Future<void> updateUsername(String newUsername) async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(username: newUsername);
    await updateUser(updatedUser);
  }

  Future<void> updateAvatar(String avatarPath) async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(avatarPath: avatarPath);
    await updateUser(updatedUser);
  }

  Future<void> addXP(int xp) async {
    if (_currentUser == null) return;

    final newTotalXP = _currentUser!.totalXP + xp;
    final updatedUser = _currentUser!.copyWith(
      totalXP: newTotalXP,
      lastActivity: DateTime.now(),
    );
    
    await updateUser(updatedUser);
  }

  Future<void> updateStreak() async {
    if (_currentUser == null) return;

    final now = DateTime.now();
    final lastActivity = _currentUser!.lastActivity;
    
    int newStreak = 1;
    
    if (lastActivity != null) {
      final daysDiff = now.difference(lastActivity).inDays;
      final isSameDay = now.day == lastActivity.day &&
          now.month == lastActivity.month &&
          now.year == lastActivity.year;
      
      if (isSameDay) {
        // Same day, keep current streak
        newStreak = _currentUser!.currentStreak;
      } else if (daysDiff == 1) {
        // Consecutive day, increase streak
        newStreak = _currentUser!.currentStreak + 1;
      }
      // If daysDiff > 1, streak is broken (newStreak = 1)
    }

    final updatedUser = _currentUser!.copyWith(
      currentStreak: newStreak,
      lastActivity: now,
    );
    
    await updateUser(updatedUser);
  }

  Future<void> updateLastActivity() async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      lastActivity: DateTime.now(),
    );
    
    await updateUser(updatedUser);
  }

  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      preferences: {..._currentUser!.preferences, ...preferences},
    );
    
    await updateUser(updatedUser);
  }

  Future<Map<String, dynamic>> getUserStats() async {
    if (_currentUser == null) {
      return {
        'totalXP': 0,
        'currentStreak': 0,
        'totalRuns': 0,
        'averageScore': 0.0,
        'exerciseTypeStats': <String, dynamic>{},
      };
    }

    return await _databaseService.getUserStats(_currentUser!.id);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    
    _currentUser = null;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (_currentUser == null) return;

    // Note: In a real app, you might want to keep some data for analytics
    // or allow account recovery. For this demo, we'll just clear the current user.
    
    await logout();
  }

  // Helper methods for UI
  String get displayName => _currentUser?.username ?? 'Guest';
  
  String get avatarPath => _currentUser?.avatarPath ?? 'assets/images/default_avatar.png';
  
  int get totalXP => _currentUser?.totalXP ?? 0;
  
  int get currentStreak => _currentUser?.currentStreak ?? 0;
  
  int get level => _currentUser?.level ?? 1;
  
  int get xpToNextLevel => _currentUser?.xpToNextLevel ?? 1000;
  
  double get levelProgress => _currentUser?.levelProgress ?? 0.0;

  // Achievement checking
  List<Achievement> checkAchievements() {
    if (_currentUser == null) return [];

    final achievements = <Achievement>[];
    final user = _currentUser!;

    // XP milestones
    if (user.totalXP >= 1000) achievements.add(Achievement.firstThousand);
    if (user.totalXP >= 5000) achievements.add(Achievement.fiveThousand);
    if (user.totalXP >= 10000) achievements.add(Achievement.tenThousand);

    // Streak milestones
    if (user.currentStreak >= 7) achievements.add(Achievement.weekStreak);
    if (user.currentStreak >= 30) achievements.add(Achievement.monthStreak);
    if (user.currentStreak >= 100) achievements.add(Achievement.hundredStreak);

    // Level milestones
    if (user.level >= 5) achievements.add(Achievement.level5);
    if (user.level >= 10) achievements.add(Achievement.level10);
    if (user.level >= 25) achievements.add(Achievement.level25);

    return achievements;
  }

  double getStreakMultiplier() {
    if (_currentUser == null) return 1.0;
    return 1.0 + (_currentUser!.currentStreak * 0.1); // 10% bonus per streak day
  }
}

enum Achievement {
  firstThousand,
  fiveThousand,
  tenThousand,
  weekStreak,
  monthStreak,
  hundredStreak,
  level5,
  level10,
  level25,
}

extension AchievementExtension on Achievement {
  String get title {
    switch (this) {
      case Achievement.firstThousand:
        return 'First Thousand';
      case Achievement.fiveThousand:
        return 'Five Thousand';
      case Achievement.tenThousand:
        return 'Ten Thousand';
      case Achievement.weekStreak:
        return 'Week Warrior';
      case Achievement.monthStreak:
        return 'Month Master';
      case Achievement.hundredStreak:
        return 'Century Streak';
      case Achievement.level5:
        return 'Level 5';
      case Achievement.level10:
        return 'Level 10';
      case Achievement.level25:
        return 'Level 25';
    }
  }

  String get description {
    switch (this) {
      case Achievement.firstThousand:
        return 'Earned your first 1,000 XP';
      case Achievement.fiveThousand:
        return 'Reached 5,000 XP milestone';
      case Achievement.tenThousand:
        return 'Achieved 10,000 XP!';
      case Achievement.weekStreak:
        return '7 days in a row!';
      case Achievement.monthStreak:
        return '30 days in a row!';
      case Achievement.hundredStreak:
        return '100 days in a row!';
      case Achievement.level5:
        return 'Reached Level 5';
      case Achievement.level10:
        return 'Reached Level 10';
      case Achievement.level25:
        return 'Reached Level 25';
    }
  }

  String get iconPath {
    switch (this) {
      case Achievement.firstThousand:
      case Achievement.fiveThousand:
      case Achievement.tenThousand:
        return 'assets/images/xp_achievement.png';
      case Achievement.weekStreak:
      case Achievement.monthStreak:
      case Achievement.hundredStreak:
        return 'assets/images/streak_achievement.png';
      case Achievement.level5:
      case Achievement.level10:
      case Achievement.level25:
        return 'assets/images/level_achievement.png';
    }
  }
}