const express = require('express');
const { getDatabase } = require('../database/database');
const { asyncHandler } = require('../middleware/errorHandler');

const router = express.Router();

// GET /api/leaderboard
router.get('/', asyncHandler(async (req, res) => {
  const { limit = 50 } = req.query;
  const db = getDatabase();
  
  const leaderboard = await new Promise((resolve, reject) => {
    db.all(
      `SELECT user_id, username, total_xp, current_streak, last_activity
       FROM users 
       ORDER BY total_xp DESC, current_streak DESC 
       LIMIT ?`,
      [parseInt(limit)],
      (err, rows) => {
        if (err) reject(err);
        else resolve(rows);
      }
    );
  });

  // Add rank to each entry
  const rankedLeaderboard = leaderboard.map((entry, index) => ({
    rank: index + 1,
    ...entry
  }));

  res.json({
    success: true,
    leaderboard: rankedLeaderboard
  });
}));

// GET /api/leaderboard/:userId
router.get('/:userId', asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const db = getDatabase();
  
  // Get user's stats and rank
  const userStats = await new Promise((resolve, reject) => {
    db.get(
      'SELECT user_id, username, total_xp, current_streak, last_activity FROM users WHERE user_id = ?',
      [userId],
      (err, row) => {
        if (err) reject(err);
        else resolve(row);
      }
    );
  });

  if (!userStats) {
    return res.status(404).json({
      success: false,
      error: 'User not found'
    });
  }

  // Get user's rank
  const rank = await new Promise((resolve, reject) => {
    db.get(
      'SELECT COUNT(*) + 1 as rank FROM users WHERE total_xp > ? OR (total_xp = ? AND current_streak > ?)',
      [userStats.total_xp, userStats.total_xp, userStats.current_streak],
      (err, row) => {
        if (err) reject(err);
        else resolve(row.rank);
      }
    );
  });

  // Get total number of users
  const totalUsers = await new Promise((resolve, reject) => {
    db.get(
      'SELECT COUNT(*) as total FROM users',
      (err, row) => {
        if (err) reject(err);
        else resolve(row.total);
      }
    );
  });

  res.json({
    success: true,
    userStats: {
      ...userStats,
      rank,
      totalUsers
    }
  });
}));

// GET /api/leaderboard/stats/global
router.get('/stats/global', asyncHandler(async (req, res) => {
  const db = getDatabase();
  
  const stats = await new Promise((resolve, reject) => {
    db.get(
      `SELECT 
         COUNT(*) as totalUsers,
         AVG(total_xp) as avgXP,
         MAX(total_xp) as maxXP,
         AVG(current_streak) as avgStreak,
         MAX(current_streak) as maxStreak,
         COUNT(CASE WHEN last_activity >= date('now', '-1 day') THEN 1 END) as activeToday
       FROM users`,
      (err, row) => {
        if (err) reject(err);
        else resolve(row);
      }
    );
  });

  // Get exercise type distribution
  const exerciseStats = await new Promise((resolve, reject) => {
    db.all(
      `SELECT 
         exercise_type,
         COUNT(*) as count,
         AVG(xp_earned) as avgXP
       FROM exercise_runs 
       GROUP BY exercise_type`,
      (err, rows) => {
        if (err) reject(err);
        else resolve(rows);
      }
    );
  });

  res.json({
    success: true,
    globalStats: {
      ...stats,
      avgXP: Math.round(stats.avgXP || 0),
      avgStreak: Math.round(stats.avgStreak || 0),
      exerciseStats
    }
  });
}));

module.exports = router;