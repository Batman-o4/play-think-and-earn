import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skillstreak/main.dart';
import 'package:skillstreak/services/database_service.dart';
import 'package:skillstreak/services/api_service.dart';
import 'package:skillstreak/services/user_service.dart';
import 'package:skillstreak/services/course_service.dart';
import 'package:skillstreak/models/user.dart';
import 'package:skillstreak/models/course.dart';
import 'package:skillstreak/widgets/user_stats_card.dart';
import 'package:skillstreak/widgets/quick_play_card.dart';

void main() {
  group('Widget Tests', () {
    late DatabaseService mockDatabaseService;
    late ApiService mockApiService;

    setUp(() {
      mockDatabaseService = MockDatabaseService();
      mockApiService = MockApiService();
    });

    testWidgets('UserStatsCard displays user information correctly', (WidgetTester tester) async {
      final user = User(
        id: 'test-user',
        username: 'TestUser',
        totalXP: 1500,
        currentStreak: 5,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserStatsCard(user: user),
          ),
        ),
      );

      expect(find.text('TestUser'), findsOneWidget);
      expect(find.text('Level 2'), findsOneWidget);
      expect(find.text('1500 XP'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('UserStatsCard shows loading when user is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserStatsCard(user: null),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('QuickPlayCard responds to tap', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickPlayCard(
              title: 'Test Exercise',
              icon: Icons.play_arrow,
              color: Colors.blue,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Test Exercise'), findsOneWidget);

      await tester.tap(find.byType(QuickPlayCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('App initializes with onboarding when no user', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<DatabaseService>.value(value: mockDatabaseService),
            Provider<ApiService>.value(value: mockApiService),
            ChangeNotifierProvider<UserService>(
              create: (_) => UserService(mockDatabaseService),
            ),
            ChangeNotifierProxyProvider2<DatabaseService, ApiService, CourseService>(
              create: (_) => CourseService(mockDatabaseService, mockApiService),
              update: (_, db, api, __) => CourseService(db, api),
            ),
          ],
          child: const MaterialApp(
            home: AppInitializer(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show onboarding screen
      expect(find.text('Welcome to\nSkillStreak!'), findsOneWidget);
    });
  });

  group('Model Tests', () {
    test('User model correctly calculates level and progress', () {
      final user = User(
        id: 'test-user',
        username: 'TestUser',
        totalXP: 2500,
        currentStreak: 3,
        createdAt: DateTime.now(),
      );

      expect(user.level, equals(3)); // 2500 XP = level 3
      expect(user.xpToNextLevel, equals(500)); // 3000 - 2500 = 500
      expect(user.levelProgress, equals(0.5)); // 500/1000 = 0.5
    });

    test('Course model correctly determines unlock status', () {
      final course = Course(
        id: 'test-course',
        title: 'Test Course',
        description: 'A test course',
        unlockXP: 1000,
        exercises: [],
        createdAt: DateTime.now(),
      );

      expect(course.isUnlocked(500), isFalse);
      expect(course.isUnlocked(1000), isTrue);
      expect(course.isUnlocked(1500), isTrue);
    });

    test('Exercise model generates correct display names', () {
      final traceExercise = Exercise(
        id: 'trace-a',
        type: 'trace',
        difficulty: 1,
        data: {'letter': 'A'},
      );

      final countExercise = Exercise(
        id: 'count-shapes',
        type: 'count',
        difficulty: 2,
        data: {'objects': 'circles'},
      );

      final rhythmExercise = Exercise(
        id: 'rhythm-basic',
        type: 'rhythm',
        difficulty: 1,
        data: {'bpm': 60},
      );

      expect(traceExercise.displayName, equals('Trace "A"'));
      expect(countExercise.displayName, equals('Count circles'));
      expect(rhythmExercise.displayName, equals('Rhythm 60 BPM'));
    });
  });

  group('Service Tests', () {
    test('UserService correctly calculates streak multiplier', () {
      final databaseService = MockDatabaseService();
      final userService = UserService(databaseService);

      // Mock user with 5-day streak
      final user = User(
        id: 'test-user',
        username: 'TestUser',
        currentStreak: 5,
        createdAt: DateTime.now(),
      );

      userService.setCurrentUser(user);

      expect(userService.getStreakMultiplier(), equals(1.5)); // 1.0 + (5 * 0.1)
    });

    test('UserService correctly identifies achievements', () {
      final databaseService = MockDatabaseService();
      final userService = UserService(databaseService);

      final user = User(
        id: 'test-user',
        username: 'TestUser',
        totalXP: 1500,
        currentStreak: 10,
        createdAt: DateTime.now(),
      );

      userService.setCurrentUser(user);

      final achievements = userService.checkAchievements();
      
      expect(achievements.contains(Achievement.firstThousand), isTrue);
      expect(achievements.contains(Achievement.weekStreak), isTrue);
      expect(achievements.contains(Achievement.level5), isFalse); // Level 2, not 5
    });
  });
}

// Mock classes for testing
class MockDatabaseService extends DatabaseService {
  @override
  Future<void> initialize() async {
    // Mock implementation
  }

  @override
  Future<User?> getUser(String userId) async {
    return null; // No user initially
  }

  @override
  Future<List<Course>> getAllCourses() async {
    return [];
  }
}

class MockApiService extends ApiService {
  @override
  Future<bool> isBackendAvailable() async {
    return false; // Simulate offline mode
  }
}

// Extension for testing
extension UserServiceTest on UserService {
  void setCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
}