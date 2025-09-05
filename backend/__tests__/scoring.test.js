const { calculateTraceScore, calculateCountScore, calculateRhythmScore } = require('../src/services/scoringService');

describe('Scoring Service', () => {
  describe('calculateTraceScore', () => {
    test('should return 0 accuracy for empty trace', () => {
      const runData = {
        tracePoints: [],
        templatePoints: [
          { x: 100, y: 100, timestamp: 0 },
          { x: 200, y: 100, timestamp: 100 }
        ],
        timeSpent: 5000
      };

      const result = calculateTraceScore(runData);
      expect(result.accuracy).toBe(0);
    });

    test('should calculate score for valid trace', () => {
      const runData = {
        tracePoints: [
          { x: 105, y: 105, timestamp: 0 },
          { x: 195, y: 105, timestamp: 100 }
        ],
        templatePoints: [
          { x: 100, y: 100, timestamp: 0 },
          { x: 200, y: 100, timestamp: 100 }
        ],
        timeSpent: 3000
      };

      const result = calculateTraceScore(runData);
      expect(result.accuracy).toBeGreaterThan(50);
      expect(result.details).toHaveProperty('pathSimilarity');
      expect(result.details).toHaveProperty('coverage');
      expect(result.details).toHaveProperty('speedPenalty');
    });

    test('should penalize very fast completion', () => {
      const runData = {
        tracePoints: [
          { x: 100, y: 100, timestamp: 0 },
          { x: 200, y: 100, timestamp: 100 }
        ],
        templatePoints: [
          { x: 100, y: 100, timestamp: 0 },
          { x: 200, y: 100, timestamp: 100 }
        ],
        timeSpent: 500 // Very fast
      };

      const result = calculateTraceScore(runData);
      expect(result.details.speedPenalty).toBeGreaterThan(0);
    });
  });

  describe('calculateCountScore', () => {
    test('should return perfect score for exact match', () => {
      const runData = {
        userCount: 5,
        correctCount: 5,
        timeSpent: 3000
      };

      const result = calculateCountScore(runData);
      expect(result.accuracy).toBe(100);
      expect(result.details.isExact).toBe(true);
    });

    test('should return high score for close guess', () => {
      const runData = {
        userCount: 4,
        correctCount: 5,
        timeSpent: 3000
      };

      const result = calculateCountScore(runData);
      expect(result.accuracy).toBe(85);
      expect(result.details.difference).toBe(1);
    });

    test('should apply speed bonus for quick accurate answers', () => {
      const runData = {
        userCount: 5,
        correctCount: 5,
        timeSpent: 2000 // Quick response
      };

      const result = calculateCountScore(runData);
      expect(result.details.speedBonus).toBeGreaterThan(0);
    });

    test('should handle invalid input', () => {
      const runData = {
        userCount: 'invalid',
        correctCount: 5,
        timeSpent: 3000
      };

      const result = calculateCountScore(runData);
      expect(result.accuracy).toBe(0);
    });
  });

  describe('calculateRhythmScore', () => {
    test('should return 0 accuracy for no taps', () => {
      const runData = {
        taps: [],
        expectedTaps: [
          { timestamp: 1000, isCorrect: false },
          { timestamp: 2000, isCorrect: false }
        ],
        bpm: 60
      };

      const result = calculateRhythmScore(runData);
      expect(result.accuracy).toBe(0);
    });

    test('should calculate score for rhythm exercise', () => {
      const runData = {
        taps: [
          { timestamp: 1050, isCorrect: false }, // 50ms off
          { timestamp: 2100, isCorrect: false }  // 100ms off
        ],
        expectedTaps: [
          { timestamp: 1000, isCorrect: false },
          { timestamp: 2000, isCorrect: false }
        ],
        bpm: 60
      };

      const result = calculateRhythmScore(runData);
      expect(result.accuracy).toBeGreaterThan(0);
      expect(result.details).toHaveProperty('correctTaps');
      expect(result.details).toHaveProperty('timingAccuracy');
      expect(result.details).toHaveProperty('averageOffset');
    });

    test('should penalize extra taps', () => {
      const runData = {
        taps: [
          { timestamp: 1000, isCorrect: false },
          { timestamp: 1500, isCorrect: false }, // Extra tap
          { timestamp: 2000, isCorrect: false }
        ],
        expectedTaps: [
          { timestamp: 1000, isCorrect: false },
          { timestamp: 2000, isCorrect: false }
        ],
        bpm: 60
      };

      const result = calculateRhythmScore(runData);
      expect(result.details.extraTaps).toBe(1);
    });

    test('should handle empty expected taps', () => {
      const runData = {
        taps: [{ timestamp: 1000, isCorrect: false }],
        expectedTaps: [],
        bpm: 60
      };

      const result = calculateRhythmScore(runData);
      expect(result.accuracy).toBe(0);
    });
  });
});