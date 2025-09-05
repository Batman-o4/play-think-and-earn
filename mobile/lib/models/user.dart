class User {
  final String id;
  final String username;
  final String? avatarPath;
  final int totalXP;
  final int currentStreak;
  final DateTime? lastActivity;
  final DateTime createdAt;
  final Map<String, dynamic> preferences;

  User({
    required this.id,
    required this.username,
    this.avatarPath,
    this.totalXP = 0,
    this.currentStreak = 0,
    this.lastActivity,
    required this.createdAt,
    this.preferences = const {},
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      username: map['username'] as String,
      avatarPath: map['avatar_path'] as String?,
      totalXP: map['total_xp'] as int? ?? 0,
      currentStreak: map['current_streak'] as int? ?? 0,
      lastActivity: map['last_activity'] != null 
          ? DateTime.parse(map['last_activity'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      preferences: map['preferences'] != null
          ? Map<String, dynamic>.from(map['preferences'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'avatar_path': avatarPath,
      'total_xp': totalXP,
      'current_streak': currentStreak,
      'last_activity': lastActivity?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'preferences': preferences,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? avatarPath,
    int? totalXP,
    int? currentStreak,
    DateTime? lastActivity,
    DateTime? createdAt,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarPath: avatarPath ?? this.avatarPath,
      totalXP: totalXP ?? this.totalXP,
      currentStreak: currentStreak ?? this.currentStreak,
      lastActivity: lastActivity ?? this.lastActivity,
      createdAt: createdAt ?? this.createdAt,
      preferences: preferences ?? this.preferences,
    );
  }

  int get level => (totalXP / 1000).floor() + 1;
  int get xpToNextLevel => ((level * 1000) - totalXP);
  double get levelProgress => (totalXP % 1000) / 1000.0;

  @override
  String toString() {
    return 'User(id: $id, username: $username, totalXP: $totalXP, streak: $currentStreak)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}