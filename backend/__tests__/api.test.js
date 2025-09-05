const request = require('supertest');
const app = require('../src/server');

describe('API Endpoints', () => {
  describe('Health Check', () => {
    test('GET /health should return 200', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body).toHaveProperty('status', 'ok');
      expect(response.body).toHaveProperty('timestamp');
    });
  });

  describe('Exercise Validation', () => {
    test('POST /api/exercises/validateRun should validate trace exercise', async () => {
      const runData = {
        userId: 'test-user-123',
        exerciseType: 'trace',
        exerciseId: 'trace-a',
        runData: {
          tracePoints: [
            { x: 100, y: 100, timestamp: 0 },
            { x: 200, y: 100, timestamp: 100 }
          ],
          templatePoints: [
            { x: 100, y: 100, timestamp: 0 },
            { x: 200, y: 100, timestamp: 100 }
          ],
          timeSpent: 3000
        }
      };

      const response = await request(app)
        .post('/api/exercises/validateRun')
        .send(runData)
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('score');
      expect(response.body.score).toHaveProperty('accuracy');
      expect(response.body.score).toHaveProperty('xp');
      expect(response.body.score).toHaveProperty('multiplier');
    });

    test('POST /api/exercises/validateRun should validate count exercise', async () => {
      const runData = {
        userId: 'test-user-123',
        exerciseType: 'count',
        exerciseId: 'count-shapes-1',
        runData: {
          userCount: 3,
          correctCount: 3,
          timeSpent: 5000
        }
      };

      const response = await request(app)
        .post('/api/exercises/validateRun')
        .send(runData)
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body.score.accuracy).toBe(100);
    });

    test('POST /api/exercises/validateRun should validate rhythm exercise', async () => {
      const runData = {
        userId: 'test-user-123',
        exerciseType: 'rhythm',
        exerciseId: 'rhythm-basic-1',
        runData: {
          taps: [
            { timestamp: 1000, isCorrect: false },
            { timestamp: 2000, isCorrect: false }
          ],
          expectedTaps: [
            { timestamp: 1000, isCorrect: false },
            { timestamp: 2000, isCorrect: false }
          ],
          bpm: 60
        }
      };

      const response = await request(app)
        .post('/api/exercises/validateRun')
        .send(runData)
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body.score).toHaveProperty('accuracy');
    });

    test('POST /api/exercises/validateRun should return 400 for invalid data', async () => {
      const runData = {
        userId: 'test-user-123',
        exerciseType: 'invalid-type',
        exerciseId: 'test-exercise',
        runData: {}
      };

      const response = await request(app)
        .post('/api/exercises/validateRun')
        .send(runData)
        .expect(400);

      expect(response.body).toHaveProperty('success', false);
      expect(response.body).toHaveProperty('error');
    });

    test('POST /api/exercises/validateRun should return 400 for missing fields', async () => {
      const runData = {
        exerciseType: 'trace',
        runData: {}
      };

      const response = await request(app)
        .post('/api/exercises/validateRun')
        .send(runData)
        .expect(400);

      expect(response.body).toHaveProperty('success', false);
    });
  });

  describe('Courses', () => {
    test('GET /api/courses should return courses list', async () => {
      const response = await request(app)
        .get('/api/courses')
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('courses');
      expect(Array.isArray(response.body.courses)).toBe(true);
    });

    test('GET /api/courses/:courseId should return specific course', async () => {
      const response = await request(app)
        .get('/api/courses/basics-alphabet')
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('course');
      expect(response.body.course).toHaveProperty('id', 'basics-alphabet');
    });

    test('GET /api/courses/:courseId should return 404 for non-existent course', async () => {
      const response = await request(app)
        .get('/api/courses/non-existent-course')
        .expect(404);

      expect(response.body).toHaveProperty('success', false);
    });
  });

  describe('Leaderboard', () => {
    test('GET /api/leaderboard should return leaderboard', async () => {
      const response = await request(app)
        .get('/api/leaderboard')
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('leaderboard');
      expect(Array.isArray(response.body.leaderboard)).toBe(true);
    });

    test('GET /api/leaderboard should accept limit parameter', async () => {
      const response = await request(app)
        .get('/api/leaderboard?limit=10')
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body.leaderboard.length).toBeLessThanOrEqual(10);
    });

    test('GET /api/leaderboard/stats/global should return global stats', async () => {
      const response = await request(app)
        .get('/api/leaderboard/stats/global')
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('globalStats');
      expect(response.body.globalStats).toHaveProperty('totalUsers');
    });
  });

  describe('Rate Limiting', () => {
    test('should rate limit excessive requests', async () => {
      const userId = 'rate-limit-test-user';
      const runData = {
        userId,
        exerciseType: 'trace',
        exerciseId: 'trace-test',
        runData: {
          tracePoints: [{ x: 100, y: 100, timestamp: 0 }],
          templatePoints: [{ x: 100, y: 100, timestamp: 0 }],
          timeSpent: 1000
        }
      };

      // Make 12 requests quickly (should exceed the 10 per minute limit)
      const promises = [];
      for (let i = 0; i < 12; i++) {
        promises.push(
          request(app)
            .post('/api/exercises/validateRun')
            .send({ ...runData, userId: `${userId}-${i}` })
        );
      }

      const responses = await Promise.all(promises);
      
      // At least one should be rate limited
      const rateLimitedResponses = responses.filter(r => r.status === 429);
      expect(rateLimitedResponses.length).toBeGreaterThan(0);
    }, 10000);
  });

  describe('Error Handling', () => {
    test('should return 404 for non-existent routes', async () => {
      const response = await request(app)
        .get('/api/non-existent-endpoint')
        .expect(404);

      expect(response.body).toHaveProperty('error');
    });

    test('should handle malformed JSON', async () => {
      const response = await request(app)
        .post('/api/exercises/validateRun')
        .set('Content-Type', 'application/json')
        .send('{"invalid": json}')
        .expect(400);
    });
  });
});