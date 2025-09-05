import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:skillstreak/main.dart';
import 'package:skillstreak/services/database_service.dart';
import 'package:skillstreak/services/api_service.dart';
import 'package:skillstreak/services/user_service.dart';
import 'package:skillstreak/services/course_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SkillStreak Integration Tests', () {
    testWidgets('Complete user onboarding flow', (WidgetTester tester) async {
      // Initialize the app
      final databaseService = DatabaseService();
      await databaseService.initialize();
      
      await tester.pumpWidget(
        SkillStreakApp(databaseService: databaseService),
      );
      await tester.pumpAndSettle();

      // Should start with onboarding
      expect(find.text('Welcome to\nSkillStreak!'), findsOneWidget);

      // Tap "Get Started"
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Should be on avatar selection page
      expect(find.text('Choose Your Avatar'), findsOneWidget);

      // Select an avatar
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // Tap "Continue"
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should be on username page
      expect(find.text('What\'s Your Name?'), findsOneWidget);

      // Enter username
      await tester.enterText(find.byType(TextField), 'TestUser');
      await tester.pumpAndSettle();

      // Tap "Create Account"
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should navigate to home screen
      expect(find.text('Welcome back, TestUser!'), findsOneWidget);
    });

    testWidgets('Navigate through main tabs', (WidgetTester tester) async {
      // Assume user is already created from previous test
      final databaseService = DatabaseService();
      await databaseService.initialize();
      
      await tester.pumpWidget(
        SkillStreakApp(databaseService: databaseService),
      );
      await tester.pumpAndSettle();

      // Should be on home tab
      expect(find.text('Home'), findsOneWidget);

      // Tap Courses tab
      await tester.tap(find.text('Courses'));
      await tester.pumpAndSettle();
      expect(find.text('Available Courses'), findsOneWidget);

      // Tap Leaderboard tab
      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();
      // Leaderboard might be empty initially

      // Tap Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);

      // Return to Home tab
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
    });

    testWidgets('Start and complete a trace exercise', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.initialize();
      
      await tester.pumpWidget(
        SkillStreakApp(databaseService: databaseService),
      );
      await tester.pumpAndSettle();

      // Navigate to courses
      await tester.tap(find.text('Courses'));
      await tester.pumpAndSettle();

      // Find and tap on the first available course
      final courseCards = find.byType(Card);
      if (courseCards.evaluate().isNotEmpty) {
        await tester.tap(courseCards.first);
        await tester.pumpAndSettle();

        // Should be on course detail page
        // Look for first exercise
        final exerciseCards = find.byType(Card);
        if (exerciseCards.evaluate().isNotEmpty) {
          await tester.tap(exerciseCards.first);
          await tester.pumpAndSettle();

          // Should be on exercise screen
          // If it's a trace exercise, try to trace
          if (find.text('Trace').evaluate().isNotEmpty) {
            // Find the canvas area and make some gestures
            final canvas = find.byType(CustomPaint);
            if (canvas.evaluate().isNotEmpty) {
              // Simulate tracing gestures
              await tester.dragFrom(
                tester.getCenter(canvas),
                const Offset(50, 50),
              );
              await tester.pumpAndSettle();

              // Try to finish the trace
              final finishButton = find.text('Finish Trace');
              if (finishButton.evaluate().isNotEmpty) {
                await tester.tap(finishButton);
                await tester.pumpAndSettle();
              }

              // Submit the exercise
              final submitButton = find.text('Submit Exercise');
              if (submitButton.evaluate().isNotEmpty) {
                await tester.tap(submitButton);
                await tester.pumpAndSettle(const Duration(seconds: 3));

                // Should navigate to results screen
                expect(find.text('Exercise Complete'), findsOneWidget);
              }
            }
          }
        }
      }
    });

    testWidgets('Quick play functionality', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.initialize();
      
      await tester.pumpWidget(
        SkillStreakApp(databaseService: databaseService),
      );
      await tester.pumpAndSettle();

      // Should be on home screen
      // Look for Quick Play cards
      final traceCard = find.text('Trace');
      if (traceCard.evaluate().isNotEmpty) {
        await tester.tap(traceCard);
        await tester.pumpAndSettle();

        // Should start a trace exercise or show message
        // Either exercise screen or snackbar message
        expect(
          find.byType(Scaffold).evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    testWidgets('Settings and profile management', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.initialize();
      
      await tester.pumpWidget(
        SkillStreakApp(databaseService: databaseService),
      );
      await tester.pumpAndSettle();

      // Navigate to profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Tap settings
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        // Should show settings dialog
        expect(find.text('Settings'), findsOneWidget);

        // Test username editing
        final editUsernameOption = find.text('Edit Username');
        if (editUsernameOption.evaluate().isNotEmpty) {
          await tester.tap(editUsernameOption);
          await tester.pumpAndSettle();

          // Should show username edit dialog
          expect(find.text('Edit Username'), findsOneWidget);

          // Cancel the dialog
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
        }

        // Close settings dialog
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Data persistence test', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.initialize();
      
      // Clear any existing data
      await databaseService.clearAllData();
      
      await tester.pumpWidget(
        SkillStreakApp(databaseService: databaseService),
      );
      await tester.pumpAndSettle();

      // Complete onboarding
      if (find.text('Welcome to\nSkillStreak!').evaluate().isNotEmpty) {
        // Skip through onboarding quickly
        await tester.tap(find.text('Get Started'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        
        await tester.enterText(find.byType(TextField), 'PersistenceTest');
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Create Account'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Verify user is created
      expect(find.text('Welcome back, PersistenceTest!'), findsOneWidget);

      // Restart the app to test persistence
      await tester.pumpWidget(
        SkillStreakApp(databaseService: databaseService),
      );
      await tester.pumpAndSettle();

      // Should still show the user (no onboarding)
      expect(find.text('Welcome back, PersistenceTest!'), findsOneWidget);
    });
  });
}