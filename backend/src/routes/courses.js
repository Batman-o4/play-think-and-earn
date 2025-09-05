const express = require('express');
const { getDatabase } = require('../database/database');
const { asyncHandler } = require('../middleware/errorHandler');

const router = express.Router();

// GET /api/courses
router.get('/', asyncHandler(async (req, res) => {
  const db = getDatabase();
  
  const courses = await new Promise((resolve, reject) => {
    db.all(
      'SELECT id, title, description, unlock_xp, exercises FROM courses ORDER BY unlock_xp ASC',
      (err, rows) => {
        if (err) reject(err);
        else resolve(rows.map(row => ({
          ...row,
          exercises: JSON.parse(row.exercises)
        })));
      }
    );
  });

  res.json({
    success: true,
    courses
  });
}));

// GET /api/courses/:courseId
router.get('/:courseId', asyncHandler(async (req, res) => {
  const { courseId } = req.params;
  const db = getDatabase();
  
  const course = await new Promise((resolve, reject) => {
    db.get(
      'SELECT id, title, description, unlock_xp, exercises FROM courses WHERE id = ?',
      [courseId],
      (err, row) => {
        if (err) reject(err);
        else resolve(row);
      }
    );
  });

  if (!course) {
    return res.status(404).json({
      success: false,
      error: 'Course not found'
    });
  }

  res.json({
    success: true,
    course: {
      ...course,
      exercises: JSON.parse(course.exercises)
    }
  });
}));

// GET /api/courses/:courseId/progress/:userId
router.get('/:courseId/progress/:userId', asyncHandler(async (req, res) => {
  const { courseId, userId } = req.params;
  const db = getDatabase();
  
  const progress = await new Promise((resolve, reject) => {
    db.get(
      'SELECT completed_exercises, progress_percent FROM user_progress WHERE user_id = ? AND course_id = ?',
      [userId, courseId],
      (err, row) => {
        if (err) reject(err);
        else resolve(row);
      }
    );
  });

  if (!progress) {
    // No progress yet, return empty progress
    return res.json({
      success: true,
      progress: {
        completedExercises: [],
        progressPercent: 0
      }
    });
  }

  res.json({
    success: true,
    progress: {
      completedExercises: JSON.parse(progress.completed_exercises),
      progressPercent: progress.progress_percent
    }
  });
}));

// POST /api/courses/:courseId/progress/:userId
router.post('/:courseId/progress/:userId', asyncHandler(async (req, res) => {
  const { courseId, userId } = req.params;
  const { exerciseId } = req.body;
  
  if (!exerciseId) {
    return res.status(400).json({
      success: false,
      error: 'Exercise ID is required'
    });
  }

  const db = getDatabase();
  
  // Get current progress
  const currentProgress = await new Promise((resolve, reject) => {
    db.get(
      'SELECT completed_exercises FROM user_progress WHERE user_id = ? AND course_id = ?',
      [userId, courseId],
      (err, row) => {
        if (err) reject(err);
        else resolve(row);
      }
    );
  });

  let completedExercises = [];
  if (currentProgress) {
    completedExercises = JSON.parse(currentProgress.completed_exercises);
  }

  // Add new exercise if not already completed
  if (!completedExercises.includes(exerciseId)) {
    completedExercises.push(exerciseId);
  }

  // Get total exercises in course to calculate progress
  const course = await new Promise((resolve, reject) => {
    db.get(
      'SELECT exercises FROM courses WHERE id = ?',
      [courseId],
      (err, row) => {
        if (err) reject(err);
        else resolve(row);
      }
    );
  });

  if (!course) {
    return res.status(404).json({
      success: false,
      error: 'Course not found'
    });
  }

  const totalExercises = JSON.parse(course.exercises).length;
  const progressPercent = Math.round((completedExercises.length / totalExercises) * 100);

  // Update or insert progress
  await new Promise((resolve, reject) => {
    db.run(
      `INSERT OR REPLACE INTO user_progress 
       (user_id, course_id, completed_exercises, progress_percent, updated_at) 
       VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)`,
      [userId, courseId, JSON.stringify(completedExercises), progressPercent],
      function(err) {
        if (err) reject(err);
        else resolve(this.lastID);
      }
    );
  });

  res.json({
    success: true,
    progress: {
      completedExercises,
      progressPercent
    }
  });
}));

module.exports = router;