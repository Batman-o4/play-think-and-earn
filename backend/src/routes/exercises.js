const express = require('express');
const Joi = require('joi');
const { getDatabase } = require('../database/database');
const { asyncHandler } = require('../middleware/errorHandler');
const { calculateTraceScore, calculateCountScore, calculateRhythmScore } = require('../services/scoringService');
const { updateUserStats } = require('../services/userService');

const router = express.Router();

// Validation schemas
const validateRunSchema = Joi.object({
  userId: Joi.string().required(),
  exerciseType: Joi.string().valid('trace', 'count', 'rhythm').required(),
  courseId: Joi.string().optional(),
  exerciseId: Joi.string().required(),
  runData: Joi.object().required()
});

// POST /api/exercises/validateRun
router.post('/validateRun', asyncHandler(async (req, res) => {
  const { error, value } = validateRunSchema.validate(req.body);
  if (error) {
    return res.status(400).json({
      success: false,
      error: error.details[0].message
    });
  }

  const { userId, exerciseType, courseId, exerciseId, runData } = value;
  
  // Rate limiting check - max 10 runs per minute per user
  const db = getDatabase();
  const oneMinuteAgo = new Date(Date.now() - 60000).toISOString();
  
  const recentRuns = await new Promise((resolve, reject) => {
    db.get(
      'SELECT COUNT(*) as count FROM exercise_runs WHERE user_id = ? AND completed_at > ?',
      [userId, oneMinuteAgo],
      (err, row) => {
        if (err) reject(err);
        else resolve(row.count);
      }
    );
  });

  if (recentRuns >= 10) {
    return res.status(429).json({
      success: false,
      error: 'Rate limit exceeded. Maximum 10 runs per minute.'
    });
  }

  let scoreResult;
  
  try {
    // Calculate score based on exercise type
    switch (exerciseType) {
      case 'trace':
        scoreResult = calculateTraceScore(runData);
        break;
      case 'count':
        scoreResult = calculateCountScore(runData);
        break;
      case 'rhythm':
        scoreResult = calculateRhythmScore(runData);
        break;
      default:
        throw new Error('Invalid exercise type');
    }

    // Get user's current streak multiplier
    const user = await new Promise((resolve, reject) => {
      db.get(
        'SELECT current_streak, last_activity FROM users WHERE user_id = ?',
        [userId],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    let streakMultiplier = 1.0;
    if (user) {
      const lastActivity = user.last_activity ? new Date(user.last_activity) : null;
      const today = new Date();
      const isConsecutiveDay = lastActivity && 
        (today.toDateString() !== lastActivity.toDateString()) &&
        ((today - lastActivity) / (1000 * 60 * 60 * 24) <= 1);
      
      if (isConsecutiveDay) {
        streakMultiplier = 1 + (user.current_streak * 0.1); // 10% bonus per streak day
      }
    }

    // Calculate final XP with multiplier
    const baseXP = 100;
    const finalXP = Math.floor(scoreResult.accuracy * baseXP * streakMultiplier / 100);

    // Store the run
    await new Promise((resolve, reject) => {
      db.run(
        'INSERT INTO exercise_runs (user_id, exercise_type, course_id, exercise_id, score_data, xp_earned) VALUES (?, ?, ?, ?, ?, ?)',
        [userId, exerciseType, courseId, exerciseId, JSON.stringify(scoreResult), finalXP],
        function(err) {
          if (err) reject(err);
          else resolve(this.lastID);
        }
      );
    });

    // Update user stats
    await updateUserStats(userId, finalXP);

    res.json({
      success: true,
      score: {
        accuracy: scoreResult.accuracy,
        details: scoreResult.details,
        xp: finalXP,
        multiplier: streakMultiplier,
        baseScore: scoreResult.accuracy
      }
    });

  } catch (error) {
    console.error('Scoring error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to calculate score'
    });
  }
}));

// GET /api/exercises/history/:userId
router.get('/history/:userId', asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const { limit = 50, offset = 0 } = req.query;

  const db = getDatabase();
  
  const history = await new Promise((resolve, reject) => {
    db.all(
      `SELECT exercise_type, course_id, exercise_id, score_data, xp_earned, completed_at 
       FROM exercise_runs 
       WHERE user_id = ? 
       ORDER BY completed_at DESC 
       LIMIT ? OFFSET ?`,
      [userId, parseInt(limit), parseInt(offset)],
      (err, rows) => {
        if (err) reject(err);
        else resolve(rows.map(row => ({
          ...row,
          score_data: JSON.parse(row.score_data)
        })));
      }
    );
  });

  res.json({
    success: true,
    history
  });
}));

module.exports = router;