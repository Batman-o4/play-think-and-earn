class Run {
  final int? id;
  final String exerciseType;
  final String exerciseId;
  final Map<String, dynamic> runData;
  final double score;
  final int xpEarned;
  final DateTime timestamp;
  final bool validated;

  Run({
    this.id,
    required this.exerciseType,
    required this.exerciseId,
    required this.runData,
    required this.score,
    required this.xpEarned,
    required this.timestamp,
    this.validated = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exerciseType': exerciseType,
      'exerciseId': exerciseId,
      'runData': runData.toString(),
      'score': score,
      'xpEarned': xpEarned,
      'timestamp': timestamp.toIso8601String(),
      'validated': validated ? 1 : 0,
    };
  }

  factory Run.fromMap(Map<String, dynamic> map) {
    return Run(
      id: map['id'],
      exerciseType: map['exerciseType'],
      exerciseId: map['exerciseId'],
      runData: Map<String, dynamic>.from(
        map['runData'] is String 
          ? Uri.splitQueryString(map['runData'])
          : map['runData'] ?? {}
      ),
      score: map['score']?.toDouble() ?? 0.0,
      xpEarned: map['xpEarned'] ?? 0,
      timestamp: DateTime.parse(map['timestamp']),
      validated: map['validated'] == 1,
    );
  }
}

class TraceRunData {
  final List<Offset> points;
  final String letter;
  final double width;
  final double height;

  TraceRunData({
    required this.points,
    required this.letter,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'letter': letter,
      'width': width,
      'height': height,
    };
  }

  factory TraceRunData.fromJson(Map<String, dynamic> json) {
    return TraceRunData(
      points: (json['points'] as List)
          .map((p) => Offset(p['x'].toDouble(), p['y'].toDouble()))
          .toList(),
      letter: json['letter'],
      width: json['width'].toDouble(),
      height: json['height'].toDouble(),
    );
  }
}

class CountRunData {
  final int guessedCount;
  final String imageId;
  final List<Rect> boundingBoxes;

  CountRunData({
    required this.guessedCount,
    required this.imageId,
    required this.boundingBoxes,
  });

  Map<String, dynamic> toJson() {
    return {
      'guessedCount': guessedCount,
      'imageId': imageId,
      'boundingBoxes': boundingBoxes.map((r) => {
        'left': r.left,
        'top': r.top,
        'right': r.right,
        'bottom': r.bottom,
      }).toList(),
    };
  }

  factory CountRunData.fromJson(Map<String, dynamic> json) {
    return CountRunData(
      guessedCount: json['guessedCount'],
      imageId: json['imageId'],
      boundingBoxes: (json['boundingBoxes'] as List)
          .map((b) => Rect.fromLTRB(
            b['left'].toDouble(),
            b['top'].toDouble(),
            b['right'].toDouble(),
            b['bottom'].toDouble(),
          ))
          .toList(),
    );
  }
}

class RhythmRunData {
  final List<int> tapTimes;
  final List<int> expectedTimes;
  final double bpm;

  RhythmRunData({
    required this.tapTimes,
    required this.expectedTimes,
    required this.bpm,
  });

  Map<String, dynamic> toJson() {
    return {
      'tapTimes': tapTimes,
      'expectedTimes': expectedTimes,
      'bpm': bpm,
    };
  }

  factory RhythmRunData.fromJson(Map<String, dynamic> json) {
    return RhythmRunData(
      tapTimes: List<int>.from(json['tapTimes']),
      expectedTimes: List<int>.from(json['expectedTimes']),
      bpm: json['bpm'].toDouble(),
    );
  }
}

// Import Offset and Rect from Flutter
import 'package:flutter/material.dart';