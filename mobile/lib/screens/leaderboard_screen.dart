import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardEntry> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Try to load from backend first
      final leaderboard = await ApiService.instance.getLeaderboard();
      
      if (leaderboard.isNotEmpty) {
        setState(() {
          _leaderboard = leaderboard;
          _isLoading = false;
        });
      } else {
        // Fallback to local database
        final localData = await DatabaseService.instance.getLeaderboard();
        final entries = localData.map((data) => LeaderboardEntry.fromJson(data)).toList();
        
        setState(() {
          _leaderboard = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _leaderboard.isEmpty
              ? _buildEmptyState()
              : _buildLeaderboard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No leaderboard data yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some exercises to see your ranking!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadLeaderboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leaderboard.length,
      itemBuilder: (context, index) {
        final entry = _leaderboard[index];
        final isTopThree = index < 3;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: isTopThree
                ? Border.all(
                    color: _getRankColor(index),
                    width: 2,
                  )
                : null,
          ),
          child: Row(
            children: [
              // Rank
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isTopThree ? _getRankColor(index) : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${entry.rank}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isTopThree ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Avatar
              Text(
                entry.avatar,
                style: const TextStyle(fontSize: 32),
              ),
              
              const SizedBox(width: 16),
              
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.username,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.totalXP} XP',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: Colors.orange[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.currentStreak} day streak',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Trophy for top 3
              if (isTopThree) ...[
                Icon(
                  Icons.emoji_events,
                  size: 24,
                  color: _getRankColor(index),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey[300]!;
    }
  }
}