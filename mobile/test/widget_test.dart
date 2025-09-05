import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillstreak/main.dart';
import 'package:skillstreak/screens/trace_screen.dart';
import 'package:skillstreak/screens/count_screen.dart';
import 'package:skillstreak/screens/rhythm_screen.dart';

void main() {
  group('SkillStreak Widget Tests', () {
    testWidgets('App should start with onboarding screen', (WidgetTester tester) async {
      await tester.pumpWidget(const SkillStreakApp());
      await tester.pumpAndSettle();

      expect(find.text('SkillStreak'), findsOneWidget);
      expect(find.text('Gamified Micro-Learning'), findsOneWidget);
      expect(find.text('Let\'s get started!'), findsOneWidget);
    });

    testWidgets('Trace screen should display letter and canvas', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TraceScreen()));
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('Draw the letter A'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Validate'), findsOneWidget);
    });

    testWidgets('Count screen should display image and number input', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CountScreen()));
      await tester.pumpAndSettle();

      expect(find.text('🍎'), findsOneWidget);
      expect(find.text('How many apples do you see?'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Check Answer'), findsOneWidget);
    });

    testWidgets('Rhythm screen should display beat and tap area', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RhythmScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Tap along with the beat!'), findsOneWidget);
      expect(find.text('BPM: 120'), findsOneWidget);
      expect(find.text('TAP!'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('Number pad should work in count screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CountScreen()));
      await tester.pumpAndSettle();

      // Tap number 5
      await tester.tap(find.text('5'));
      await tester.pump();

      expect(find.text('5'), findsOneWidget);

      // Tap number 3
      await tester.tap(find.text('3'));
      await tester.pump();

      expect(find.text('53'), findsOneWidget);
    });

    testWidgets('Letter selection should work in trace screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TraceScreen()));
      await tester.pumpAndSettle();

      // Tap letter B
      await tester.tap(find.text('B'));
      await tester.pump();

      expect(find.text('B'), findsOneWidget);
      expect(find.text('Draw the letter B'), findsOneWidget);
    });

    testWidgets('Clear button should reset count', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CountScreen()));
      await tester.pumpAndSettle();

      // Enter some numbers
      await tester.tap(find.text('5'));
      await tester.tap(find.text('3'));
      await tester.pump();

      expect(find.text('53'), findsOneWidget);

      // Clear
      await tester.tap(find.text('Clear'));
      await tester.pump();

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('BPM slider should work in rhythm screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RhythmScreen()));
      await tester.pumpAndSettle();

      // Find and drag the slider
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      await tester.drag(slider, const Offset(100, 0));
      await tester.pump();

      // BPM should have changed
      expect(find.textContaining('BPM:'), findsOneWidget);
    });
  });
}