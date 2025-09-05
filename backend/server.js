const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const bodyParser = require('body-parser');
const rateLimit = require('express-rate-limit');
const compression = require('compression');
const path = require('path');
const fs = require('fs');

const DatabaseService = require('./src/services/DatabaseService');
const RunController = require('./src/controllers/RunController');
const CourseController = require('./src/controllers/CourseController');
const LeaderboardController = require('./src/controllers/LeaderboardController');
const ScoringService = require('./src/services/ScoringService');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors({
  origin: ['http://localhost:3000', 'http://127.0.0.1:3000'],
  credentials: true
}));
app.use(bodyParser.json({ limit: '10mb' }));
app.use(bodyParser.urlencoded({ extended: true }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// Initialize database
const dbService = new DatabaseService();
dbService.init().then(() => {
  console.log('Database initialized successfully');
}).catch(err => {
  console.error('Database initialization failed:', err);
});

// Initialize services
const scoringService = new ScoringService();
const runController = new RunController(scoringService);
const courseController = new CourseController();
const leaderboardController = new LeaderboardController();

// Routes
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.post('/api/validateRun', async (req, res) => {
  try {
    const result = await runController.validateRun(req.body);
    res.json(result);
  } catch (error) {
    console.error('Error validating run:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/courses', async (req, res) => {
  try {
    const courses = await courseController.getCourses();
    res.json(courses);
  } catch (error) {
    console.error('Error fetching courses:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/leaderboard', async (req, res) => {
  try {
    const leaderboard = await leaderboardController.getLeaderboard();
    res.json(leaderboard);
  } catch (error) {
    console.error('Error fetching leaderboard:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/leaderboard', async (req, res) => {
  try {
    await leaderboardController.updateLeaderboard(req.body);
    res.json({ success: true });
  } catch (error) {
    console.error('Error updating leaderboard:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Start server
app.listen(PORT, () => {
  console.log(`SkillStreak Backend running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});

module.exports = app;