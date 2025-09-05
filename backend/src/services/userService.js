const { getDatabase } = require('../database/database');

/**
 * Update user statistics after completing an exercise
 * @param {string} userId - User ID
 * @param {number} xpEarned - XP earned from the exercise
 */
async function updateUserStats(userId, xpEarned) {
  const db = getDatabase();
  
  return new Promise((resolve, reject) => {
    // Get current user data
    db.get(
      'SELECT total_xp, current_streak, last_activity FROM users WHERE user_id = ?',
      [userId],
      (err, user) => {
        if (err) {
          reject(err);
          return;
        }

        const today = new Date();
        const todayString = today.toISOString().split('T')[0];
        
        let newTotalXP = xpEarned;
        let newStreak = 1;
        
        if (user) {
          newTotalXP = user.total_xp + xpEarned;
          
          const lastActivity = user.last_activity ? new Date(user.last_activity) : null;
          const lastActivityString = lastActivity ? lastActivity.toISOString().split('T')[0] : null;
          
          if (lastActivityString === todayString) {
            // Same day, keep current streak
            newStreak = user.current_streak;
          } else if (lastActivity) {
            const daysDiff = (today - lastActivity) / (1000 * 60 * 60 * 24);
            if (daysDiff <= 1.5) { // Allow some tolerance for time zones
              // Consecutive day
              newStreak = user.current_streak + 1;
            } else {
              // Streak broken
              newStreak = 1;
            }
          }
        }

        // Update or insert user
        db.run(
          `INSERT OR REPLACE INTO users 
           (user_id, username, total_xp, current_streak, last_activity) 
           VALUES (?, ?, ?, ?, ?)`,
          [
            userId,
            user?.username || `User_${userId.substring(0, 8)}`,
            newTotalXP,
            newStreak,
            today.toISOString()
          ],
          function(err) {
            if (err) {
              reject(err);
            } else {
              resolve({
                totalXP: newTotalXP,
                currentStreak: newStreak,
                xpEarned
              });
            }
          }
        );
      }
    );
  });
}

/**
 * Get user profile and stats
 * @param {string} userId - User ID
 */
async function getUserProfile(userId) {
  const db = getDatabase();
  
  return new Promise((resolve, reject) => {
    db.get(
      'SELECT user_id, username, total_xp, current_streak, last_activity, created_at FROM users WHERE user_id = ?',
      [userId],
      (err, user) => {
        if (err) {
          reject(err);
          return;
        }
        
        if (!user) {
          resolve(null);
          return;
        }

        // Get additional stats
        db.all(
          `SELECT 
             exercise_type,
             COUNT(*) as count,
             AVG(xp_earned) as avgXP,
             MAX(xp_earned) as maxXP
           FROM exercise_runs 
           WHERE user_id = ? 
           GROUP BY exercise_type`,
          [userId],
          (err, exerciseStats) => {
            if (err) {
              reject(err);
              return;
            }

            resolve({
              ...user,
              exerciseStats: exerciseStats || []
            });
          }
        );
      }
    );
  });
}

/**
 * Update user's username
 * @param {string} userId - User ID
 * @param {string} username - New username
 */
async function updateUsername(userId, username) {
  const db = getDatabase();
  
  return new Promise((resolve, reject) => {
    db.run(
      'UPDATE users SET username = ? WHERE user_id = ?',
      [username, userId],
      function(err) {
        if (err) {
          reject(err);
        } else {
          resolve(this.changes > 0);
        }
      }
    );
  });
}

/**
 * Get user's course progress summary
 * @param {string} userId - User ID
 */
async function getUserCourseProgress(userId) {
  const db = getDatabase();
  
  return new Promise((resolve, reject) => {
    db.all(
      `SELECT 
         up.course_id,
         c.title,
         up.progress_percent,
         up.updated_at,
         c.unlock_xp
       FROM user_progress up
       JOIN courses c ON up.course_id = c.id
       WHERE up.user_id = ?
       ORDER BY up.updated_at DESC`,
      [userId],
      (err, progress) => {
        if (err) {
          reject(err);
          return;
        }

        resolve(progress || []);
      }
    );
  });
}

module.exports = {
  updateUserStats,
  getUserProfile,
  updateUsername,
  getUserCourseProgress
};