const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const DB_PATH = path.join(__dirname, '../data/skillstreak.db');

let db;

function initializeDatabase() {
  return new Promise((resolve, reject) => {
    // Ensure data directory exists
    require('fs').mkdirSync(path.dirname(DB_PATH), { recursive: true });
    
    db = new sqlite3.Database(DB_PATH, (err) => {
      if (err) {
        reject(err);
        return;
      }
      
      console.log('Connected to SQLite database');
      createTables()
        .then(() => seedData())
        .then(resolve)
        .catch(reject);
    });
  });
}

function createTables() {
  return new Promise((resolve, reject) => {
    const queries = [
      // Users table for leaderboard
      `CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT UNIQUE NOT NULL,
        username TEXT NOT NULL,
        total_xp INTEGER DEFAULT 0,
        current_streak INTEGER DEFAULT 0,
        last_activity DATE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`,
      
      // Exercise runs table
      `CREATE TABLE IF NOT EXISTS exercise_runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        exercise_type TEXT NOT NULL,
        course_id TEXT,
        exercise_id TEXT,
        score_data TEXT, -- JSON string
        xp_earned INTEGER,
        completed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )`,
      
      // Courses table
      `CREATE TABLE IF NOT EXISTS courses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        unlock_xp INTEGER DEFAULT 0,
        exercises TEXT, -- JSON string of exercise list
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`,
      
      // User progress table
      `CREATE TABLE IF NOT EXISTS user_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        course_id TEXT NOT NULL,
        completed_exercises TEXT, -- JSON array of completed exercise IDs
        progress_percent INTEGER DEFAULT 0,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (user_id),
        FOREIGN KEY (course_id) REFERENCES courses (id),
        UNIQUE(user_id, course_id)
      )`
    ];
    
    let completed = 0;
    queries.forEach((query) => {
      db.run(query, (err) => {
        if (err) {
          reject(err);
          return;
        }
        completed++;
        if (completed === queries.length) {
          resolve();
        }
      });
    });
  });
}

function seedData() {
  return new Promise((resolve, reject) => {
    // Check if courses already exist
    db.get('SELECT COUNT(*) as count FROM courses', (err, row) => {
      if (err) {
        reject(err);
        return;
      }
      
      if (row.count > 0) {
        console.log('Database already seeded');
        resolve();
        return;
      }
      
      // Seed courses
      const courses = [
        {
          id: 'basics-alphabet',
          title: 'Alphabet Basics',
          description: 'Learn to trace letters A-Z',
          unlock_xp: 0,
          exercises: JSON.stringify([
            { id: 'trace-a', type: 'trace', letter: 'A', difficulty: 1 },
            { id: 'trace-b', type: 'trace', letter: 'B', difficulty: 1 },
            { id: 'trace-c', type: 'trace', letter: 'C', difficulty: 1 },
            { id: 'count-shapes-1', type: 'count', objects: 'circles', count: 3, difficulty: 1 },
            { id: 'rhythm-basic-1', type: 'rhythm', bpm: 60, pattern: [1,0,1,0], difficulty: 1 }
          ])
        },
        {
          id: 'intermediate-words',
          title: 'Word Formation',
          description: 'Combine letters into simple words',
          unlock_xp: 500,
          exercises: JSON.stringify([
            { id: 'trace-cat', type: 'trace', word: 'CAT', difficulty: 2 },
            { id: 'count-animals', type: 'count', objects: 'animals', count: 5, difficulty: 2 },
            { id: 'rhythm-medium-1', type: 'rhythm', bpm: 80, pattern: [1,0,1,1,0,1,0,0], difficulty: 2 }
          ])
        },
        {
          id: 'advanced-patterns',
          title: 'Pattern Recognition',
          description: 'Complex patterns and rhythms',
          unlock_xp: 1500,
          exercises: JSON.stringify([
            { id: 'trace-cursive', type: 'trace', style: 'cursive', word: 'Hello', difficulty: 3 },
            { id: 'count-complex', type: 'count', objects: 'mixed', count: 8, difficulty: 3 },
            { id: 'rhythm-complex-1', type: 'rhythm', bpm: 120, pattern: [1,0,1,0,1,1,0,1,0,0,1,0], difficulty: 3 }
          ])
        }
      ];
      
      let completed = 0;
      const stmt = db.prepare('INSERT INTO courses (id, title, description, unlock_xp, exercises) VALUES (?, ?, ?, ?, ?)');
      
      courses.forEach((course) => {
        stmt.run([course.id, course.title, course.description, course.unlock_xp, course.exercises], (err) => {
          if (err) {
            reject(err);
            return;
          }
          completed++;
          if (completed === courses.length) {
            stmt.finalize();
            console.log('Database seeded with courses');
            resolve();
          }
        });
      });
    });
  });
}

function getDatabase() {
  return db;
}

module.exports = {
  initializeDatabase,
  getDatabase
};