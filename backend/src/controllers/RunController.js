class RunController {
  constructor(scoringService) {
    this.scoringService = scoringService;
  }

  async validateRun(runData) {
    try {
      const { exerciseType, exerciseId, runData: data, xpEarned } = runData;
      
      let validationResult;
      
      switch (exerciseType) {
        case 'trace':
          validationResult = this.scoringService.validateTraceRun(data);
          break;
        case 'count':
          validationResult = this.scoringService.validateCountRun(data);
          break;
        case 'rhythm':
          validationResult = this.scoringService.validateRhythmRun(data);
          break;
        default:
          throw new Error(`Unknown exercise type: ${exerciseType}`);
      }

      const score = validationResult.score;
      const feedback = validationResult.feedback;
      
      // Calculate XP based on score
      const calculatedXP = this.scoringService.calculateXP(score, xpEarned);
      
      // Anti-cheat: Basic validation
      const isValidRun = this.validateRunIntegrity(runData, score);
      
      return {
        validated: isValidRun,
        score: score,
        xpEarned: isValidRun ? calculatedXP : 0,
        feedback: feedback,
        timestamp: new Date().toISOString(),
        exerciseType: exerciseType,
        exerciseId: exerciseId
      };
    } catch (error) {
      console.error('Error validating run:', error);
      return {
        validated: false,
        score: 0,
        xpEarned: 0,
        feedback: 'Error processing run',
        timestamp: new Date().toISOString(),
        error: error.message
      };
    }
  }

  validateRunIntegrity(runData, score) {
    try {
      // Basic anti-cheat measures
      
      // Check if run data is reasonable
      if (!runData.runData || typeof runData.runData !== 'object') {
        return false;
      }

      // Check for impossible scores
      if (score < 0 || score > 100) {
        return false;
      }

      // Check for suspicious patterns
      const data = runData.runData;
      
      switch (runData.exerciseType) {
        case 'trace':
          return this.validateTraceIntegrity(data);
        case 'count':
          return this.validateCountIntegrity(data);
        case 'rhythm':
          return this.validateRhythmIntegrity(data);
        default:
          return false;
      }
    } catch (error) {
      console.error('Error validating run integrity:', error);
      return false;
    }
  }

  validateTraceIntegrity(data) {
    const points = data.points || [];
    const letter = data.letter || '';
    
    // Check if points array is reasonable
    if (!Array.isArray(points) || points.length === 0) {
      return false;
    }

    // Check if points have valid structure
    for (const point of points) {
      if (typeof point.x !== 'number' || typeof point.y !== 'number') {
        return false;
      }
      if (!isFinite(point.x) || !isFinite(point.y)) {
        return false;
      }
    }

    // Check if letter is valid
    if (typeof letter !== 'string' || letter.length !== 1) {
      return false;
    }

    return true;
  }

  validateCountIntegrity(data) {
    const guessedCount = data.guessedCount;
    const imageId = data.imageId;
    
    // Check if guessed count is reasonable
    if (typeof guessedCount !== 'number' || !Number.isInteger(guessedCount)) {
      return false;
    }
    
    if (guessedCount < 0 || guessedCount > 1000) {
      return false;
    }

    // Check if image ID is valid
    if (typeof imageId !== 'string' || imageId.length === 0) {
      return false;
    }

    return true;
  }

  validateRhythmIntegrity(data) {
    const tapTimes = data.tapTimes || [];
    const expectedTimes = data.expectedTimes || [];
    const bpm = data.bpm;
    
    // Check if arrays are valid
    if (!Array.isArray(tapTimes) || !Array.isArray(expectedTimes)) {
      return false;
    }

    // Check if BPM is reasonable
    if (typeof bpm !== 'number' || bpm < 60 || bpm > 300) {
      return false;
    }

    // Check if tap times are reasonable
    for (const time of tapTimes) {
      if (typeof time !== 'number' || !Number.isInteger(time)) {
        return false;
      }
      if (time < 0 || time > Date.now() + 60000) { // Not more than 1 minute in future
        return false;
      }
    }

    return true;
  }
}

module.exports = RunController;