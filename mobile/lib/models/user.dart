class User {
  final int? id;
  final String username;
  final String avatar;
  final int totalXP;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActiveDate;
  final int walletPoints;
  final List<String> unlockedCourses;
  final List<String> unlockedThemes;
  final List<String> unlockedBadges;

  User({
    this.id,
    required this.username,
    required this.avatar,
    this.totalXP = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.lastActiveDate,
    this.walletPoints = 0,
    this.unlockedCourses = const [],
    this.unlockedThemes = const [],
    this.unlockedBadges = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'avatar': avatar,
      'totalXP': totalXP,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate.toIso8601String(),
      'walletPoints': walletPoints,
      'unlockedCourses': unlockedCourses.join(','),
      'unlockedThemes': unlockedThemes.join(','),
      'unlockedBadges': unlockedBadges.join(','),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      avatar: map['avatar'],
      totalXP: map['totalXP'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastActiveDate: DateTime.parse(map['lastActiveDate']),
      walletPoints: map['walletPoints'] ?? 0,
      unlockedCourses: map['unlockedCourses']?.split(',') ?? [],
      unlockedThemes: map['unlockedThemes']?.split(',') ?? [],
      unlockedBadges: map['unlockedBadges']?.split(',') ?? [],
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? avatar,
    int? totalXP,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    int? walletPoints,
    List<String>? unlockedCourses,
    List<String>? unlockedThemes,
    List<String>? unlockedBadges,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      totalXP: totalXP ?? this.totalXP,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      walletPoints: walletPoints ?? this.walletPoints,
      unlockedCourses: unlockedCourses ?? this.unlockedCourses,
      unlockedThemes: unlockedThemes ?? this.unlockedThemes,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
    );
  }
}