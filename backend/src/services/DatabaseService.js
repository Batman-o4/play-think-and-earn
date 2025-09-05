const sqlite3 = require('sqlite3').verbose();
const path = require('path');

class DatabaseService {
  constructor() {
    this.db = null;
    this.dbPath = path.join(__dirname, '../../data/skillstreak.db');
  }

  async init() {
    return new Promise((resolve, reject) => {
      // Ensure data directory exists
      const dataDir = path.dirname(this.dbPath);
      if (!require('fs').existsSync(dataDir)) {
        require('fs').mkdirSync(dataDir, { recursive: true });
      }

      this.db = new sqlite3.Database(this.dbPath, (err) => {
        if (err) {
          console.error('Error opening database:', err);
          reject(err);
        } else {
          console.log('Connected to SQLite database');
          this.createTables().then(resolve).catch(reject);
        }
      });
    });
  }

  async createTables() {
    return new Promise((resolve, reject) => {
      const createTablesSQL = `
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          avatar TEXT NOT NULL,
          totalXP INTEGER DEFAULT 0,
          currentStreak INTEGER DEFAULT 0,
          longestStreak INTEGER DEFAULT 0,
          lastActiveDate TEXT NOT NULL,
          walletPoints INTEGER DEFAULT 0,
          unlockedCourses TEXT DEFAULT '',
          unlockedThemes TEXT DEFAULT '',
          unlockedBadges TEXT DEFAULT '',
          createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
          updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS runs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER,
          exerciseType TEXT NOT NULL,
          exerciseId TEXT NOT NULL,
          runData TEXT NOT NULL,
          score REAL NOT NULL,
          xpEarned INTEGER NOT NULL,
          timestamp TEXT NOT NULL,
          validated INTEGER DEFAULT 0,
          createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (userId) REFERENCES users (id)
        );

        CREATE TABLE IF NOT EXISTS leaderboard (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL,
          avatar TEXT NOT NULL,
          totalXP INTEGER NOT NULL,
          currentStreak INTEGER NOT NULL,
          rank INTEGER NOT NULL,
          lastUpdated TEXT NOT NULL,
          createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS courses (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          icon TEXT NOT NULL,
          requiredXP INTEGER NOT NULL,
          exercises TEXT NOT NULL,
          unlocked INTEGER DEFAULT 0,
          createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
        );
      `;

      this.db.exec(createTablesSQL, (err) => {
        if (err) {
          console.error('Error creating tables:', err);
          reject(err);
        } else {
          console.log('Database tables created successfully');
          this.seedData().then(resolve).catch(reject);
        }
      });
    });
  }

  async seedData() {
    return new Promise((resolve, reject) => {
      // Check if data already exists
      this.db.get('SELECT COUNT(*) as count FROM courses', (err, row) => {
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
            id: 'alphabet_basics',
            title: 'Alphabet Basics',
            description: 'Learn to trace basic letters',
            icon: '🔤',
            requiredXP: 0,
            exercises: JSON.stringify([
              {
                id: 'trace_a',
                type: 'trace',
                title: 'Trace Letter A',
                description: 'Draw the letter A on the canvas',
                data: { letter: 'A' },
                baseXP: 10
              },
              {
                id: 'trace_b',
                type: 'trace',
                title: 'Trace Letter B',
                description: 'Draw the letter B on the canvas',
                data: { letter: 'B' },
                baseXP: 15
              }
            ]),
            unlocked: 1
          },
          {
            id: 'counting_fun',
            title: 'Counting Fun',
            description: 'Practice counting objects',
            icon: '🔢',
            requiredXP: 50,
            exercises: JSON.stringify([
              {
                id: 'count_apples',
                type: 'count',
                title: 'Count Apples',
                description: 'How many apples do you see?',
                data: { imageId: 'apples' },
                baseXP: 20
              }
            ]),
            unlocked: 0
          },
          {
            id: 'rhythm_master',
            title: 'Rhythm Master',
            description: 'Tap along with the beat',
            icon: '🎵',
            requiredXP: 100,
            exercises: JSON.stringify([
              {
                id: 'rhythm_basic',
                type: 'rhythm',
                title: 'Basic Rhythm',
                description: 'Tap along with the basic beat',
                data: { bpm: 120, pattern: [0, 500, 1000, 1500] },
                baseXP: 25
              }
            ]),
            unlocked: 0
          }
        ];

        const stmt = this.db.prepare(`
          INSERT INTO courses (id, title, description, icon, requiredXP, exercises, unlocked)
          VALUES (?, ?, ?, ?, ?, ?, ?)
        `);

        courses.forEach(course => {
          stmt.run([
            course.id,
            course.title,
            course.description,
            course.icon,
            course.requiredXP,
            course.exercises,
            course.unlocked
          ]);
        });

        stmt.finalize((err) => {
          if (err) {
            reject(err);
          } else {
            console.log('Database seeded successfully');
            resolve();
          }
        });
      });
    });
  }

  async getUser(username) {
    return new Promise((resolve, reject) => {
      this.db.get(
        'SELECT * FROM users WHERE username = ?',
        [username],
        (err, row) => {
          if (err) {
            reject(err);
          } else {
            resolve(row);
          }
        }
      );
    });
  }

  async createUser(userData) {
    return new Promise((resolve, reject) => {
      this.db.run(
        `INSERT INTO users (username, avatar, totalXP, currentStreak, longestStreak, lastActiveDate, walletPoints, unlockedCourses, unlockedThemes, unlockedBadges)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          userData.username,
          userData.avatar,
          userData.totalXP || 0,
          userData.currentStreak || 0,
          userData.longestStreak || 0,
          userData.lastActiveDate,
          userData.walletPoints || 0,
          userData.unlockedCourses || '',
          userData.unlockedThemes || '',
          userData.unlockedBadges || ''
        ],
        function(err) {
          if (err) {
            reject(err);
          } else {
            resolve({ id: this.lastID, ...userData });
          }
        }
      );
    });
  }

  async updateUser(userId, userData) {
    return new Promise((resolve, reject) => {
      this.db.run(
        `UPDATE users SET 
         username = ?, avatar = ?, totalXP = ?, currentStreak = ?, longestStreak = ?, 
         lastActiveDate = ?, walletPoints = ?, unlockedCourses = ?, unlockedThemes = ?, 
         unlockedBadges = ?, updatedAt = CURRENT_TIMESTAMP
         WHERE id = ?`,
        [
          userData.username,
          userData.avatar,
          userData.totalXP,
          userData.currentStreak,
          userData.longestStreak,
          userData.lastActiveDate,
          userData.walletPoints,
          userData.unlockedCourses,
          userData.unlockedThemes,
          userData.unlockedBadges,
          userId
        ],
        function(err) {
          if (err) {
            reject(err);
          } else {
            resolve({ changes: this.changes });
          }
        }
      );
    });
  }

  async insertRun(runData) {
    return new Promise((resolve, reject) => {
      this.db.run(
        `INSERT INTO runs (userId, exerciseType, exerciseId, runData, score, xpEarned, timestamp, validated)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          runData.userId,
          runData.exerciseType,
          runData.exerciseId,
          JSON.stringify(runData.runData),
          runData.score,
          runData.xpEarned,
          runData.timestamp,
          runData.validated ? 1 : 0
        ],
        function(err) {
          if (err) {
            reject(err);
          } else {
            resolve({ id: this.lastID, ...runData });
          }
        }
      );
    });
  }

  async getLeaderboard() {
    return new Promise((resolve, reject) => {
      this.db.all(
        `SELECT username, avatar, totalXP, currentStreak, rank 
         FROM leaderboard 
         ORDER BY rank ASC`,
        (err, rows) => {
          if (err) {
            reject(err);
          } else {
            resolve(rows);
          }
        }
      );
    });
  }

  async updateLeaderboard(entries) {
    return new Promise((resolve, reject) => {
      this.db.run('DELETE FROM leaderboard', (err) => {
        if (err) {
          reject(err);
          return;
        }

        const stmt = this.db.prepare(`
          INSERT INTO leaderboard (username, avatar, totalXP, currentStreak, rank, lastUpdated)
          VALUES (?, ?, ?, ?, ?, ?)
        `);

        entries.forEach(entry => {
          stmt.run([
            entry.username,
            entry.avatar,
            entry.totalXP,
            entry.currentStreak,
            entry.rank,
            new Date().toISOString()
          ]);
        });

        stmt.finalize((err) => {
          if (err) {
            reject(err);
          } else {
            resolve();
          }
        });
      });
    });
  }

  async getCourses() {
    return new Promise((resolve, reject) => {
      this.db.all('SELECT * FROM courses ORDER BY requiredXP ASC', (err, rows) => {
        if (err) {
          reject(err);
        } else {
          const courses = rows.map(row => ({
            ...row,
            exercises: JSON.parse(row.exercises),
            unlocked: row.unlocked === 1
          }));
          resolve(courses);
        }
      });
    });
  }

  close() {
    if (this.db) {
      this.db.close((err) => {
        if (err) {
          console.error('Error closing database:', err);
        } else {
          console.log('Database connection closed');
        }
      });
    }
  }
}

module.exports = DatabaseService;