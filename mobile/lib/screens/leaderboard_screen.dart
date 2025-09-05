import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillstreak/services/user_service.dart';
import 'package:skillstreak/services/database_service.dart';
import 'package:skillstreak/models/user.dart';
import 'package:skillstreak/utils/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<User> _leaderboard = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final databaseService = context.read<DatabaseService>();
      final users = await databaseService.getAllUsers();
      
      setState(() {
        _leaderboard = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLeaderboard,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load leaderboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLeaderboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_leaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No players yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to complete some exercises!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Consumer<UserService>(
      builder: (context, userService, child) {
        final currentUserId = userService.currentUser?.id;
        
        return Column(
          children: [
            // Current user's position (if not in top 3)
            if (currentUserId != null && 
                _leaderboard.length > 3 && 
                !_leaderboard.take(3).any((u) => u.id == currentUserId))
              _buildCurrentUserCard(currentUserId),
            
            // Top 3 podium
            if (_leaderboard.isNotEmpty)
              _buildPodium(),
            
            // Rest of the leaderboard
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _leaderboard.length > 3 ? _leaderboard.length - 3 : 0,
                itemBuilder: (context, index) {
                  final user = _leaderboard[index + 3];
                  final rank = index + 4;
                  final isCurrentUser = user.id == currentUserId;
                  
                  return _buildLeaderboardItem(
                    user,
                    rank,
                    isCurrentUser: isCurrentUser,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentUserCard(String currentUserId) {
    final currentUser = _leaderboard.firstWhere((u) => u.id == currentUserId);
    final rank = _leaderboard.indexOf(currentUser) + 1;
    
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Card(
        color: AppTheme.primaryColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(
                'Your Position',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildLeaderboardItem(currentUser, rank, isCurrentUser: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodium() {
    final top3 = _leaderboard.take(3).toList();
    
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          if (top3.length > 1)
            Expanded(child: _buildPodiumPlace(top3[1], 2, 120)),
          
          // 1st place
          if (top3.isNotEmpty)
            Expanded(child: _buildPodiumPlace(top3[0], 1, 160)),
          
          // 3rd place
          if (top3.length > 2)
            Expanded(child: _buildPodiumPlace(top3[2], 3, 100)),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(User user, int rank, double height) {
    final colors = [
      AppTheme.accentColor, // Gold
      Colors.grey[400]!, // Silver
      Colors.orange[300]!, // Bronze
    ];
    
    final color = colors[rank - 1];
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // User avatar
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: ClipOval(
            child: _buildUserAvatar(user),
          ),
        ),
        const SizedBox(height: 8),
        
        // Username
        Text(
          user.username,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        
        // XP
        Text(
          '${user.totalXP} XP',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        
        // Podium
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (rank == 1)
                  const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(
    User user,
    int rank, {
    required bool isCurrentUser,
  }) {
    return Card(
      color: isCurrentUser ? AppTheme.primaryColor.withOpacity(0.1) : null,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Rank
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCurrentUser ? AppTheme.primaryColor : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrentUser ? AppTheme.primaryColor : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: _buildUserAvatar(user),
              ),
            ),
            const SizedBox(width: 12),
            
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isCurrentUser ? AppTheme.primaryColor : null,
                    ),
                  ),
                  Text(
                    'Level ${user.level}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppTheme.xpColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${user.totalXP}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.xpColor,
                      ),
                    ),
                  ],
                ),
                if (user.currentStreak > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: AppTheme.streakColor,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${user.currentStreak}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.streakColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(User user) {
    if (user.avatarPath != null && user.avatarPath!.startsWith('assets/')) {
      return Image.asset(
        user.avatarPath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar(user);
        },
      );
    }
    
    return _buildDefaultAvatar(user);
  }

  Widget _buildDefaultAvatar(User user) {
    final colors = [
      Colors.red[300]!,
      Colors.blue[300]!,
      Colors.green[300]!,
      Colors.orange[300]!,
      Colors.purple[300]!,
      Colors.teal[300]!,
    ];
    
    final colorIndex = user.username.hashCode % colors.length;
    final color = colors[colorIndex];
    
    return Container(
      color: color,
      child: Center(
        child: Text(
          user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}