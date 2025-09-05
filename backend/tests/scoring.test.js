const ScoringService = require('../src/services/ScoringService');

describe('ScoringService', () => {
  let scoringService;

  beforeEach(() => {
    scoringService = new ScoringService();
  });

  describe('validateTraceRun', () => {
    test('should return 0 score for empty points', () => {
      const result = scoringService.validateTraceRun({
        points: [],
        letter: 'A',
        width: 300,
        height: 300
      });
      
      expect(result.score).toBe(0);
      expect(result.feedback).toBe('No drawing detected');
    });

    test('should return low score for insufficient points', () => {
      const result = scoringService.validateTraceRun({
        points: [{ x: 100, y: 100 }],
        letter: 'A',
        width: 300,
        height: 300
      });
      
      expect(result.score).toBeLessThan(50);
      expect(result.feedback).toBe('Try drawing more smoothly');
    });

    test('should return reasonable score for good drawing', () => {
      const points = [];
      // Create a simple A shape
      for (let i = 0; i < 20; i++) {
        points.push({ x: 100 + i * 2, y: 100 + Math.sin(i * 0.3) * 10 });
      }
      
      const result = scoringService.validateTraceRun({
        points,
        letter: 'A',
        width: 300,
        height: 300
      });
      
      expect(result.score).toBeGreaterThan(0);
      expect(result.score).toBeLessThanOrEqual(100);
      expect(typeof result.feedback).toBe('string');
    });
  });

  describe('validateCountRun', () => {
    test('should return 100 score for correct count', () => {
      const result = scoringService.validateCountRun({
        guessedCount: 5,
        imageId: 'apples'
      });
      
      expect(result.score).toBe(100);
      expect(result.feedback).toContain('Perfect');
    });

    test('should return partial score for close count', () => {
      const result = scoringService.validateCountRun({
        guessedCount: 4,
        imageId: 'apples'
      });
      
      expect(result.score).toBeGreaterThan(0);
      expect(result.score).toBeLessThan(100);
      expect(result.feedback).toContain('correct answer is 5');
    });

    test('should return 0 score for very wrong count', () => {
      const result = scoringService.validateCountRun({
        guessedCount: 50,
        imageId: 'apples'
      });
      
      expect(result.score).toBe(0);
      expect(result.feedback).toContain('correct answer is 5');
    });
  });

  describe('validateRhythmRun', () => {
    test('should return 0 score for empty taps', () => {
      const result = scoringService.validateRhythmRun({
        tapTimes: [],
        expectedTimes: [0, 500, 1000, 1500],
        bpm: 120
      });
      
      expect(result.score).toBe(0);
      expect(result.feedback).toBe('No taps detected');
    });

    test('should return high score for perfect timing', () => {
      const expectedTimes = [0, 500, 1000, 1500];
      const result = scoringService.validateRhythmRun({
        tapTimes: expectedTimes,
        expectedTimes,
        bpm: 120
      });
      
      expect(result.score).toBeGreaterThan(90);
      expect(result.feedback).toContain('Perfect rhythm');
    });

    test('should return lower score for poor timing', () => {
      const expectedTimes = [0, 500, 1000, 1500];
      const tapTimes = [0, 600, 1200, 1800]; // All late
      
      const result = scoringService.validateRhythmRun({
        tapTimes,
        expectedTimes,
        bpm: 120
      });
      
      expect(result.score).toBeLessThan(70);
      expect(result.feedback).toContain('practicing');
    });
  });

  describe('calculateXP', () => {
    test('should return minimum 1 XP', () => {
      const xp = scoringService.calculateXP(0, 10);
      expect(xp).toBe(1);
    });

    test('should return full XP for perfect score', () => {
      const xp = scoringService.calculateXP(100, 20);
      expect(xp).toBe(20);
    });

    test('should return proportional XP for partial score', () => {
      const xp = scoringService.calculateXP(50, 20);
      expect(xp).toBe(10);
    });
  });
});