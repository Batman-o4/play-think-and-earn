const RunController = require('../src/controllers/RunController');
const ScoringService = require('../src/services/ScoringService');

describe('RunController', () => {
  let runController;
  let scoringService;

  beforeEach(() => {
    scoringService = new ScoringService();
    runController = new RunController(scoringService);
  });

  describe('validateRun', () => {
    test('should validate trace run successfully', async () => {
      const runData = {
        exerciseType: 'trace',
        exerciseId: 'trace_a',
        runData: {
          points: [{ x: 100, y: 100 }, { x: 150, y: 150 }],
          letter: 'A',
          width: 300,
          height: 300
        },
        xpEarned: 10
      };

      const result = await runController.validateRun(runData);

      expect(result.validated).toBe(true);
      expect(result.score).toBeGreaterThanOrEqual(0);
      expect(result.score).toBeLessThanOrEqual(100);
      expect(typeof result.feedback).toBe('string');
      expect(result.exerciseType).toBe('trace');
      expect(result.exerciseId).toBe('trace_a');
    });

    test('should validate count run successfully', async () => {
      const runData = {
        exerciseType: 'count',
        exerciseId: 'count_apples',
        runData: {
          guessedCount: 5,
          imageId: 'apples',
          boundingBoxes: []
        },
        xpEarned: 20
      };

      const result = await runController.validateRun(runData);

      expect(result.validated).toBe(true);
      expect(result.score).toBe(100);
      expect(result.feedback).toContain('Perfect');
    });

    test('should validate rhythm run successfully', async () => {
      const runData = {
        exerciseType: 'rhythm',
        exerciseId: 'rhythm_basic',
        runData: {
          tapTimes: [0, 500, 1000, 1500],
          expectedTimes: [0, 500, 1000, 1500],
          bpm: 120
        },
        xpEarned: 25
      };

      const result = await runController.validateRun(runData);

      expect(result.validated).toBe(true);
      expect(result.score).toBeGreaterThan(90);
      expect(result.feedback).toContain('Perfect rhythm');
    });

    test('should reject invalid exercise type', async () => {
      const runData = {
        exerciseType: 'invalid',
        exerciseId: 'test',
        runData: {},
        xpEarned: 10
      };

      const result = await runController.validateRun(runData);

      expect(result.validated).toBe(false);
      expect(result.score).toBe(0);
      expect(result.xpEarned).toBe(0);
      expect(result.feedback).toBe('Error processing run');
    });
  });

  describe('validateRunIntegrity', () => {
    test('should validate trace integrity correctly', () => {
      const runData = {
        exerciseType: 'trace',
        runData: {
          points: [{ x: 100, y: 100 }, { x: 150, y: 150 }],
          letter: 'A',
          width: 300,
          height: 300
        }
      };

      const isValid = runController.validateRunIntegrity(runData, 75);
      expect(isValid).toBe(true);
    });

    test('should reject trace with invalid points', () => {
      const runData = {
        exerciseType: 'trace',
        runData: {
          points: [{ x: 'invalid', y: 100 }],
          letter: 'A',
          width: 300,
          height: 300
        }
      };

      const isValid = runController.validateRunIntegrity(runData, 75);
      expect(isValid).toBe(false);
    });

    test('should validate count integrity correctly', () => {
      const runData = {
        exerciseType: 'count',
        runData: {
          guessedCount: 5,
          imageId: 'apples',
          boundingBoxes: []
        }
      };

      const isValid = runController.validateRunIntegrity(runData, 100);
      expect(isValid).toBe(true);
    });

    test('should reject count with invalid data', () => {
      const runData = {
        exerciseType: 'count',
        runData: {
          guessedCount: 'invalid',
          imageId: 'apples',
          boundingBoxes: []
        }
      };

      const isValid = runController.validateRunIntegrity(runData, 100);
      expect(isValid).toBe(false);
    });

    test('should validate rhythm integrity correctly', () => {
      const runData = {
        exerciseType: 'rhythm',
        runData: {
          tapTimes: [0, 500, 1000, 1500],
          expectedTimes: [0, 500, 1000, 1500],
          bpm: 120
        }
      };

      const isValid = runController.validateRunIntegrity(runData, 95);
      expect(isValid).toBe(true);
    });

    test('should reject rhythm with invalid BPM', () => {
      const runData = {
        exerciseType: 'rhythm',
        runData: {
          tapTimes: [0, 500, 1000, 1500],
          expectedTimes: [0, 500, 1000, 1500],
          bpm: 500 // Too high
        }
      };

      const isValid = runController.validateRunIntegrity(runData, 95);
      expect(isValid).toBe(false);
    });
  });
});