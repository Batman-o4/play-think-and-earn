import 'package:flutter_test/flutter_test.dart';
import 'package:skillstreak/models/user.dart';
import 'package:skillstreak/models/run.dart';
import 'package:skillstreak/models/course.dart';

void main() {
  group('User Model Tests', () {
    test('should create user from map', () {
      final map = {
        'id': 1,
        'username': 'testuser',
        'avatar': '👤',
        'totalXP': 100,
        'currentStreak': 5,
        'longestStreak': 10,
        'lastActiveDate': '2023-01-01T00:00:00.000Z',
        'walletPoints': 50,
        'unlockedCourses': 'course1,course2',
        'unlockedThemes': 'theme1',
        'unlockedBadges': 'badge1,badge2,badge3',
      };

      final user = User.fromMap(map);

      expect(user.id, 1);
      expect(user.username, 'testuser');
      expect(user.avatar, '👤');
      expect(user.totalXP, 100);
      expect(user.currentStreak, 5);
      expect(user.longestStreak, 10);
      expect(user.walletPoints, 50);
      expect(user.unlockedCourses, ['course1', 'course2']);
      expect(user.unlockedThemes, ['theme1']);
      expect(user.unlockedBadges, ['badge1', 'badge2', 'badge3']);
    });

    test('should convert user to map', () {
      final user = User(
        id: 1,
        username: 'testuser',
        avatar: '👤',
        totalXP: 100,
        currentStreak: 5,
        longestStreak: 10,
        lastActiveDate: DateTime.parse('2023-01-01T00:00:00.000Z'),
        walletPoints: 50,
        unlockedCourses: ['course1', 'course2'],
        unlockedThemes: ['theme1'],
        unlockedBadges: ['badge1', 'badge2', 'badge3'],
      );

      final map = user.toMap();

      expect(map['id'], 1);
      expect(map['username'], 'testuser');
      expect(map['avatar'], '👤');
      expect(map['totalXP'], 100);
      expect(map['currentStreak'], 5);
      expect(map['longestStreak'], 10);
      expect(map['walletPoints'], 50);
      expect(map['unlockedCourses'], 'course1,course2');
      expect(map['unlockedThemes'], 'theme1');
      expect(map['unlockedBadges'], 'badge1,badge2,badge3');
    });

    test('should copy user with new values', () {
      final user = User(
        username: 'testuser',
        avatar: '👤',
        lastActiveDate: DateTime.now(),
        totalXP: 100,
      );

      final copiedUser = user.copyWith(
        totalXP: 200,
        currentStreak: 5,
      );

      expect(copiedUser.username, 'testuser');
      expect(copiedUser.avatar, '👤');
      expect(copiedUser.totalXP, 200);
      expect(copiedUser.currentStreak, 5);
    });
  });

  group('Run Model Tests', () {
    test('should create run from map', () {
      final map = {
        'id': 1,
        'exerciseType': 'trace',
        'exerciseId': 'trace_a',
        'runData': '{"points": [{"x": 100, "y": 100}]}',
        'score': 85.5,
        'xpEarned': 10,
        'timestamp': '2023-01-01T00:00:00.000Z',
        'validated': 1,
      };

      final run = Run.fromMap(map);

      expect(run.id, 1);
      expect(run.exerciseType, 'trace');
      expect(run.exerciseId, 'trace_a');
      expect(run.score, 85.5);
      expect(run.xpEarned, 10);
      expect(run.validated, true);
    });

    test('should convert run to map', () {
      final run = Run(
        id: 1,
        exerciseType: 'trace',
        exerciseId: 'trace_a',
        runData: {'points': [{'x': 100, 'y': 100}]},
        score: 85.5,
        xpEarned: 10,
        timestamp: DateTime.parse('2023-01-01T00:00:00.000Z'),
        validated: true,
      );

      final map = run.toMap();

      expect(map['id'], 1);
      expect(map['exerciseType'], 'trace');
      expect(map['exerciseId'], 'trace_a');
      expect(map['score'], 85.5);
      expect(map['xpEarned'], 10);
      expect(map['validated'], 1);
    });
  });

  group('Course Model Tests', () {
    test('should create course from JSON', () {
      final json = {
        'id': 'test_course',
        'title': 'Test Course',
        'description': 'A test course',
        'icon': '🔤',
        'requiredXP': 100,
        'exercises': [
          {
            'id': 'exercise1',
            'type': 'trace',
            'title': 'Test Exercise',
            'description': 'A test exercise',
            'data': {'letter': 'A'},
            'baseXP': 10,
          }
        ],
        'unlocked': true,
      };

      final course = Course.fromJson(json);

      expect(course.id, 'test_course');
      expect(course.title, 'Test Course');
      expect(course.description, 'A test course');
      expect(course.icon, '🔤');
      expect(course.requiredXP, 100);
      expect(course.unlocked, true);
      expect(course.exercises.length, 1);
      expect(course.exercises.first.id, 'exercise1');
    });

    test('should convert course to JSON', () {
      final exercise = Exercise(
        id: 'exercise1',
        type: 'trace',
        title: 'Test Exercise',
        description: 'A test exercise',
        data: {'letter': 'A'},
        baseXP: 10,
      );

      final course = Course(
        id: 'test_course',
        title: 'Test Course',
        description: 'A test course',
        icon: '🔤',
        requiredXP: 100,
        exercises: [exercise],
        unlocked: true,
      );

      final json = course.toJson();

      expect(json['id'], 'test_course');
      expect(json['title'], 'Test Course');
      expect(json['description'], 'A test course');
      expect(json['icon'], '🔤');
      expect(json['requiredXP'], 100);
      expect(json['unlocked'], true);
      expect(json['exercises'].length, 1);
    });
  });

  group('TraceRunData Tests', () {
    test('should create TraceRunData from JSON', () {
      final json = {
        'points': [{'x': 100.0, 'y': 200.0}, {'x': 150.0, 'y': 250.0}],
        'letter': 'A',
        'width': 300.0,
        'height': 400.0,
      };

      final traceData = TraceRunData.fromJson(json);

      expect(traceData.points.length, 2);
      expect(traceData.points.first.dx, 100.0);
      expect(traceData.points.first.dy, 200.0);
      expect(traceData.letter, 'A');
      expect(traceData.width, 300.0);
      expect(traceData.height, 400.0);
    });

    test('should convert TraceRunData to JSON', () {
      final traceData = TraceRunData(
        points: [const Offset(100.0, 200.0), const Offset(150.0, 250.0)],
        letter: 'A',
        width: 300.0,
        height: 400.0,
      );

      final json = traceData.toJson();

      expect(json['points'].length, 2);
      expect(json['points'][0]['x'], 100.0);
      expect(json['points'][0]['y'], 200.0);
      expect(json['letter'], 'A');
      expect(json['width'], 300.0);
      expect(json['height'], 400.0);
    });
  });
}