class Course {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int requiredXP;
  final List<Exercise> exercises;
  final bool unlocked;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredXP,
    required this.exercises,
    this.unlocked = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'requiredXP': requiredXP,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'unlocked': unlocked,
    };
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      requiredXP: json['requiredXP'],
      exercises: (json['exercises'] as List)
          .map((e) => Exercise.fromJson(e))
          .toList(),
      unlocked: json['unlocked'] ?? false,
    );
  }
}

class Exercise {
  final String id;
  final String type;
  final String title;
  final String description;
  final Map<String, dynamic> data;
  final int baseXP;

  Exercise({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.data,
    required this.baseXP,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'data': data,
      'baseXP': baseXP,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      description: json['description'],
      data: json['data'],
      baseXP: json['baseXP'],
    );
  }
}

class LeaderboardEntry {
  final String username;
  final String avatar;
  final int totalXP;
  final int currentStreak;
  final int rank;

  LeaderboardEntry({
    required this.username,
    required this.avatar,
    required this.totalXP,
    required this.currentStreak,
    required this.rank,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'avatar': avatar,
      'totalXP': totalXP,
      'currentStreak': currentStreak,
      'rank': rank,
    };
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      username: json['username'],
      avatar: json['avatar'],
      totalXP: json['totalXP'],
      currentStreak: json['currentStreak'],
      rank: json['rank'],
    );
  }
}