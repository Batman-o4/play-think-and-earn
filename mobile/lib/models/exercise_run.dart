class ExerciseRun {
  final String? id;
  final String userId;
  final String exerciseType;
  final String? courseId;
  final String exerciseId;
  final Map<String, dynamic> runData;
  final ExerciseScore? score;
  final DateTime completedAt;

  ExerciseRun({
    this.id,
    required this.userId,
    required this.exerciseType,
    this.courseId,
    required this.exerciseId,
    required this.runData,
    this.score,
    required this.completedAt,
  });

  factory ExerciseRun.fromMap(Map<String, dynamic> map) {
    return ExerciseRun(
      id: map['id']?.toString(),
      userId: map['user_id'] as String,
      exerciseType: map['exercise_type'] as String,
      courseId: map['course_id'] as String?,
      exerciseId: map['exercise_id'] as String,
      runData: Map<String, dynamic>.from(map['run_data'] as Map),
      score: map['score_data'] != null 
          ? ExerciseScore.fromMap(Map<String, dynamic>.from(map['score_data'] as Map))
          : null,
      completedAt: DateTime.parse(map['completed_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'exercise_type': exerciseType,
      'course_id': courseId,
      'exercise_id': exerciseId,
      'run_data': runData,
      'score_data': score?.toMap(),
      'completed_at': completedAt.toIso8601String(),
    };
  }

  ExerciseRun copyWith({
    String? id,
    String? userId,
    String? exerciseType,
    String? courseId,
    String? exerciseId,
    Map<String, dynamic>? runData,
    ExerciseScore? score,
    DateTime? completedAt,
  }) {
    return ExerciseRun(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exerciseType: exerciseType ?? this.exerciseType,
      courseId: courseId ?? this.courseId,
      exerciseId: exerciseId ?? this.exerciseId,
      runData: runData ?? this.runData,
      score: score ?? this.score,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  String toString() {
    return 'ExerciseRun(id: $id, type: $exerciseType, score: ${score?.accuracy}%)';
  }
}

class ExerciseScore {
  final double accuracy;
  final int xp;
  final double multiplier;
  final Map<String, dynamic> details;

  ExerciseScore({
    required this.accuracy,
    required this.xp,
    required this.multiplier,
    required this.details,
  });

  factory ExerciseScore.fromMap(Map<String, dynamic> map) {
    return ExerciseScore(
      accuracy: (map['accuracy'] as num).toDouble(),
      xp: map['xp'] as int,
      multiplier: (map['multiplier'] as num?)?.toDouble() ?? 1.0,
      details: Map<String, dynamic>.from(map['details'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accuracy': accuracy,
      'xp': xp,
      'multiplier': multiplier,
      'details': details,
    };
  }

  String get grade {
    if (accuracy >= 95) return 'A+';
    if (accuracy >= 90) return 'A';
    if (accuracy >= 85) return 'A-';
    if (accuracy >= 80) return 'B+';
    if (accuracy >= 75) return 'B';
    if (accuracy >= 70) return 'B-';
    if (accuracy >= 65) return 'C+';
    if (accuracy >= 60) return 'C';
    if (accuracy >= 55) return 'C-';
    if (accuracy >= 50) return 'D';
    return 'F';
  }

  bool get isPassing => accuracy >= 60;

  @override
  String toString() {
    return 'ExerciseScore(accuracy: $accuracy%, xp: $xp, grade: $grade)';
  }
}

// Specific run data classes for different exercise types

class TraceRunData {
  final List<TracePoint> tracePoints;
  final List<TracePoint> templatePoints;
  final int timeSpent;

  TraceRunData({
    required this.tracePoints,
    required this.templatePoints,
    required this.timeSpent,
  });

  factory TraceRunData.fromMap(Map<String, dynamic> map) {
    return TraceRunData(
      tracePoints: (map['tracePoints'] as List<dynamic>)
          .map((p) => TracePoint.fromMap(p as Map<String, dynamic>))
          .toList(),
      templatePoints: (map['templatePoints'] as List<dynamic>)
          .map((p) => TracePoint.fromMap(p as Map<String, dynamic>))
          .toList(),
      timeSpent: map['timeSpent'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tracePoints': tracePoints.map((p) => p.toMap()).toList(),
      'templatePoints': templatePoints.map((p) => p.toMap()).toList(),
      'timeSpent': timeSpent,
    };
  }
}

class TracePoint {
  final double x;
  final double y;
  final int timestamp;

  TracePoint({
    required this.x,
    required this.y,
    required this.timestamp,
  });

  factory TracePoint.fromMap(Map<String, dynamic> map) {
    return TracePoint(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      timestamp: map['timestamp'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'timestamp': timestamp,
    };
  }

  @override
  String toString() => 'TracePoint(x: $x, y: $y, t: $timestamp)';
}

class CountRunData {
  final int userCount;
  final int correctCount;
  final int timeSpent;

  CountRunData({
    required this.userCount,
    required this.correctCount,
    required this.timeSpent,
  });

  factory CountRunData.fromMap(Map<String, dynamic> map) {
    return CountRunData(
      userCount: map['userCount'] as int,
      correctCount: map['correctCount'] as int,
      timeSpent: map['timeSpent'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userCount': userCount,
      'correctCount': correctCount,
      'timeSpent': timeSpent,
    };
  }

  @override
  String toString() => 'CountRunData(user: $userCount, correct: $correctCount)';
}

class RhythmRunData {
  final List<RhythmTap> taps;
  final List<RhythmTap> expectedTaps;
  final int bpm;

  RhythmRunData({
    required this.taps,
    required this.expectedTaps,
    required this.bpm,
  });

  factory RhythmRunData.fromMap(Map<String, dynamic> map) {
    return RhythmRunData(
      taps: (map['taps'] as List<dynamic>)
          .map((t) => RhythmTap.fromMap(t as Map<String, dynamic>))
          .toList(),
      expectedTaps: (map['expectedTaps'] as List<dynamic>)
          .map((t) => RhythmTap.fromMap(t as Map<String, dynamic>))
          .toList(),
      bpm: map['bpm'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taps': taps.map((t) => t.toMap()).toList(),
      'expectedTaps': expectedTaps.map((t) => t.toMap()).toList(),
      'bpm': bpm,
    };
  }
}

class RhythmTap {
  final int timestamp;
  final bool isCorrect;

  RhythmTap({
    required this.timestamp,
    this.isCorrect = false,
  });

  factory RhythmTap.fromMap(Map<String, dynamic> map) {
    return RhythmTap(
      timestamp: map['timestamp'] as int,
      isCorrect: map['isCorrect'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'isCorrect': isCorrect,
    };
  }

  @override
  String toString() => 'RhythmTap(t: $timestamp, correct: $isCorrect)';
}