class LeaderboardController {
  constructor() {
    this.leaderboard = [];
  }

  async getLeaderboard() {
    // In a real implementation, this would fetch from database
    // For now, return sample data
    return [
      {
        username: 'Alex',
        avatar: '👨',
        totalXP: 1250,
        currentStreak: 15,
        rank: 1
      },
      {
        username: 'Sarah',
        avatar: '👩',
        totalXP: 1180,
        currentStreak: 12,
        rank: 2
      },
      {
        username: 'Mike',
        avatar: '🧑',
        totalXP: 980,
        currentStreak: 8,
        rank: 3
      },
      {
        username: 'Emma',
        avatar: '👧',
        totalXP: 850,
        currentStreak: 6,
        rank: 4
      },
      {
        username: 'David',
        avatar: '👦',
        totalXP: 720,
        currentStreak: 4,
        rank: 5
      },
      {
        username: 'Lisa',
        avatar: '👩',
        totalXP: 650,
        currentStreak: 3,
        rank: 6
      },
      {
        username: 'Tom',
        avatar: '👨',
        totalXP: 580,
        currentStreak: 2,
        rank: 7
      },
      {
        username: 'Anna',
        avatar: '👩',
        totalXP: 520,
        currentStreak: 1,
        rank: 8
      },
      {
            username: 'Ben',
            avatar: '👦',
            totalXP: 480,
            currentStreak: 1,
            rank: 9
          },
          {
            username: 'Grace',
            avatar: '👧',
            totalXP: 420,
            currentStreak: 0,
            rank: 10
          }
        ];
      }

      async updateLeaderboard(entries) {
        // In a real implementation, this would update the database
        this.leaderboard = entries;
        return true;
      }

      async addUserToLeaderboard(userData) {
        const { username, avatar, totalXP, currentStreak } = userData;
        
        // Find existing user
        const existingIndex = this.leaderboard.findIndex(entry => entry.username === username);
        
        if (existingIndex !== -1) {
          // Update existing user
          this.leaderboard[existingIndex] = {
            username,
            avatar,
            totalXP,
            currentStreak,
            rank: this.leaderboard[existingIndex].rank
          };
        } else {
          // Add new user
          this.leaderboard.push({
            username,
            avatar,
            totalXP,
            currentStreak,
            rank: this.leaderboard.length + 1
          });
        }
        
        // Sort by totalXP and update ranks
        this.leaderboard.sort((a, b) => b.totalXP - a.totalXP);
        this.leaderboard.forEach((entry, index) => {
          entry.rank = index + 1;
        });
        
        return true;
      }

      async getUserRank(username) {
        const user = this.leaderboard.find(entry => entry.username === username);
        return user ? user.rank : null;
      }

      async getTopUsers(limit = 10) {
        return this.leaderboard.slice(0, limit);
      }

      async getUsersAroundRank(rank, range = 2) {
        const start = Math.max(0, rank - range - 1);
        const end = Math.min(this.leaderboard.length, rank + range);
        return this.leaderboard.slice(start, end);
      }

      async getStreakLeaders(limit = 5) {
        return this.leaderboard
          .sort((a, b) => b.currentStreak - a.currentStreak)
          .slice(0, limit);
      }

      async getXPLeaders(limit = 5) {
        return this.leaderboard
          .sort((a, b) => b.totalXP - a.totalXP)
          .slice(0, limit);
      }

      async resetLeaderboard() {
        this.leaderboard = [];
        return true;
      }
    }

    module.exports = LeaderboardController;