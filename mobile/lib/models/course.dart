class Course {
  final String id;
  final String title;
  final String description;
  final int unlockXP;
  final List<Exercise> exercises;
  final DateTime createdAt;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.unlockXP,
    required this.exercises,
    required this.createdAt,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      unlockXP: map['unlock_xp'] as int,
      exercises: (map['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'unlock_xp': unlockXP,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool isUnlocked(int userXP) => userXP >= unlockXP;

  @override
  String toString() {
    return 'Course(id: $id, title: $title, exercises: ${exercises.length})';
  }
}

class Exercise {
  final String id;
  final String type; // 'trace', 'count', 'rhythm'
  final int difficulty; // 1-3
  final Map<String, dynamic> data; // Exercise-specific data

  Exercise({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.data,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as String,
      type: map['type'] as String,
      difficulty: map['difficulty'] as int,
      data: Map<String, dynamic>.from(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'difficulty': difficulty,
      ...data,
    };
  }

  String get displayName {
    switch (type) {
      case 'trace':
        if (data['letter'] != null) {
          return 'Trace "${data['letter']}"';
        } else if (data['word'] != null) {
          return 'Trace "${data['word']}"';
        }
        return 'Trace Exercise';
      case 'count':
        return 'Count ${data['objects'] ?? 'Objects'}';
      case 'rhythm':
        return 'Rhythm ${data['bpm'] ?? 60} BPM';
      default:
        return 'Exercise $id';
    }
  }

  String get description {
    switch (type) {
      case 'trace':
        if (data['letter'] != null) {
          return 'Trace the letter ${data['letter']} carefully';
        } else if (data['word'] != null) {
          return 'Trace the word "${data['word']}"';
        }
        return 'Follow the dotted line with your finger';
      case 'count':
        return 'Count the number of ${data['objects'] ?? 'objects'} in the image';
      case 'rhythm':
        return 'Tap along with the rhythm at ${data['bpm'] ?? 60} BPM';
      default:
        return 'Complete the exercise';
    }
  }

  @override
  String toString() {
    return 'Exercise(id: $id, type: $type, difficulty: $difficulty)';
  }
}

class CourseProgress {
  final String courseId;
  final String userId;
  final List<String> completedExercises;
  final int progressPercent;
  final DateTime updatedAt;

  CourseProgress({
    required this.courseId,
    required this.userId,
    required this.completedExercises,
    required this.progressPercent,
    required this.updatedAt,
  });

  factory CourseProgress.fromMap(Map<String, dynamic> map) {
    return CourseProgress(
      courseId: map['course_id'] as String,
      userId: map['user_id'] as String,
      completedExercises: List<String>.from(map['completed_exercises'] as List),
      progressPercent: map['progress_percent'] as int,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'course_id': courseId,
      'user_id': userId,
      'completed_exercises': completedExercises,
      'progress_percent': progressPercent,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool isExerciseCompleted(String exerciseId) {
    return completedExercises.contains(exerciseId);
  }

  CourseProgress copyWith({
    List<String>? completedExercises,
    int? progressPercent,
    DateTime? updatedAt,
  }) {
    return CourseProgress(
      courseId: courseId,
      userId: userId,
      completedExercises: completedExercises ?? this.completedExercises,
      progressPercent: progressPercent ?? this.progressPercent,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CourseProgress(courseId: $courseId, progress: $progressPercent%)';
  }
}