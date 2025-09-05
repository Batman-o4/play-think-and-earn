class ScoringService {
  constructor() {
    this.minPointsForLetter = {
      'A': 8, 'B': 12, 'C': 6, 'D': 10, 'E': 8, 'F': 8, 'G': 10, 'H': 10,
      'I': 4, 'J': 6, 'K': 8, 'L': 6, 'M': 12, 'N': 8, 'O': 8, 'P': 10,
      'Q': 10, 'R': 10, 'S': 8, 'T': 6, 'U': 8, 'V': 8, 'W': 12, 'X': 8,
      'Y': 8, 'Z': 8
    };

    this.correctCounts = {
      'apples': 5,
      'balls': 8,
      'cars': 3,
      'stars': 12,
      'hearts': 7,
      'flowers': 9,
      'birds': 4,
      'fish': 6
    };
  }

  validateTraceRun(runData) {
    try {
      const points = runData.points || [];
      const letter = runData.letter || '';
      const width = runData.width || 300;
      const height = runData.height || 300;

      if (points.length === 0) {
        return { score: 0, feedback: 'No drawing detected' };
      }

      // Basic validation: check if enough points were drawn
      const minPoints = this.minPointsForLetter[letter.toUpperCase()] || 6;
      if (points.length < minPoints) {
        return { 
          score: Math.max(0, (points.length / minPoints) * 50), 
          feedback: 'Try drawing more smoothly' 
        };
      }

      // Calculate complexity score based on letter
      const complexity = this.getLetterComplexity(letter);
      
      // Calculate smoothness score
      const smoothness = this.calculateSmoothness(points);
      
      // Calculate coverage score (how well the letter fills the canvas)
      const coverage = this.calculateCoverage(points, width, height);
      
      // Calculate shape accuracy (basic geometric analysis)
      const shapeAccuracy = this.calculateShapeAccuracy(points, letter);

      // Weighted score calculation
      const score = Math.min(100, 
        (smoothness * 0.3) + 
        (coverage * 0.2) + 
        (shapeAccuracy * 0.3) + 
        (complexity * 0.2)
      );

      let feedback = '';
      if (score >= 90) feedback = 'Excellent! Perfect letter formation!';
      else if (score >= 70) feedback = 'Great job! Very well done!';
      else if (score >= 50) feedback = 'Good attempt! Keep practicing!';
      else feedback = 'Keep trying! Focus on smooth strokes.';

      return { score: Math.round(score), feedback };
    } catch (error) {
      console.error('Error validating trace run:', error);
      return { score: 0, feedback: 'Error processing drawing' };
    }
  }

  validateCountRun(runData) {
    try {
      const guessedCount = runData.guessedCount || 0;
      const imageId = runData.imageId || '';
      const boundingBoxes = runData.boundingBoxes || [];

      const correctCount = this.correctCounts[imageId] || 1;

      if (guessedCount === correctCount) {
        return { 
          score: 100, 
          feedback: 'Perfect! You counted correctly!' 
        };
      }

      const difference = Math.abs(guessedCount - correctCount);
      const maxDifference = Math.max(correctCount, 1);
      
      // Calculate score based on how close the guess is
      let score = Math.max(0, ((maxDifference - difference) / maxDifference) * 100);
      
      // Bonus for being very close
      if (difference === 1) {
        score = Math.min(100, score + 20);
      }

      let feedback = '';
      if (score >= 80) feedback = 'Very close! The correct answer is ' + correctCount;
      else if (score >= 60) feedback = 'Good try! The correct answer is ' + correctCount;
      else feedback = 'Keep practicing! The correct answer is ' + correctCount;

      return { score: Math.round(score), feedback };
    } catch (error) {
      console.error('Error validating count run:', error);
      return { score: 0, feedback: 'Error processing count' };
    }
  }

  validateRhythmRun(runData) {
    try {
      const tapTimes = runData.tapTimes || [];
      const expectedTimes = runData.expectedTimes || [];
      const bpm = runData.bpm || 120;

      if (tapTimes.length === 0 || expectedTimes.length === 0) {
        return { score: 0, feedback: 'No taps detected' };
      }

      if (tapTimes.length !== expectedTimes.length) {
        return { score: 0, feedback: 'Incomplete rhythm pattern' };
      }

      // Calculate timing tolerance (10% of beat interval)
      const beatInterval = 60000 / bpm; // milliseconds per beat
      const tolerance = beatInterval * 0.1;

      let totalAccuracy = 0;
      let perfectHits = 0;
      let goodHits = 0;

      for (let i = 0; i < tapTimes.length; i++) {
        const difference = Math.abs(tapTimes[i] - expectedTimes[i]);
        
        if (difference <= tolerance) {
          perfectHits++;
          totalAccuracy += 1.0;
        } else if (difference <= tolerance * 2) {
          goodHits++;
          totalAccuracy += 0.7;
        } else {
          totalAccuracy += Math.max(0, (tolerance * 2 - difference) / (tolerance * 2));
        }
      }

      const averageAccuracy = totalAccuracy / tapTimes.length;
      const score = Math.round(averageAccuracy * 100);

      let feedback = '';
      if (score >= 90) feedback = 'Perfect rhythm! Excellent timing!';
      else if (score >= 70) feedback = 'Great rhythm! Very good timing!';
      else if (score >= 50) feedback = 'Good attempt! Try to match the beat better!';
      else feedback = 'Keep practicing! Focus on the rhythm!';

      return { score, feedback };
    } catch (error) {
      console.error('Error validating rhythm run:', error);
      return { score: 0, feedback: 'Error processing rhythm' };
    }
  }

  getLetterComplexity(letter) {
    const complexityScores = {
      'A': 80, 'B': 90, 'C': 70, 'D': 85, 'E': 75, 'F': 70, 'G': 85, 'H': 80,
      'I': 60, 'J': 70, 'K': 75, 'L': 65, 'M': 95, 'N': 80, 'O': 70, 'P': 80,
      'Q': 90, 'R': 85, 'S': 75, 'T': 65, 'U': 75, 'V': 70, 'W': 95, 'X': 80,
      'Y': 75, 'Z': 80
    };
    return complexityScores[letter.toUpperCase()] || 70;
  }

  calculateSmoothness(points) {
    if (points.length < 2) return 0;

    let totalAngleChange = 0;
    let validSegments = 0;

    for (let i = 1; i < points.length - 1; i++) {
      const p1 = points[i - 1];
      const p2 = points[i];
      const p3 = points[i + 1];

      const angle1 = Math.atan2(p2.y - p1.y, p2.x - p1.x);
      const angle2 = Math.atan2(p3.y - p2.y, p3.x - p2.x);
      
      let angleDiff = Math.abs(angle2 - angle1);
      if (angleDiff > Math.PI) {
        angleDiff = 2 * Math.PI - angleDiff;
      }

      totalAngleChange += angleDiff;
      validSegments++;
    }

    if (validSegments === 0) return 0;

    const averageAngleChange = totalAngleChange / validSegments;
    // Smoother lines have smaller angle changes
    const smoothness = Math.max(0, 100 - (averageAngleChange * 50));
    return Math.min(100, smoothness);
  }

  calculateCoverage(points, width, height) {
    if (points.length === 0) return 0;

    let minX = points[0].x, maxX = points[0].x;
    let minY = points[0].y, maxY = points[0].y;

    points.forEach(point => {
      minX = Math.min(minX, point.x);
      maxX = Math.max(maxX, point.x);
      minY = Math.min(minY, point.y);
      maxY = Math.max(maxY, point.y);
    });

    const usedWidth = maxX - minX;
    const usedHeight = maxY - minY;
    const coverage = Math.min(100, ((usedWidth * usedHeight) / (width * height)) * 100);

    return coverage;
  }

  calculateShapeAccuracy(points, letter) {
    // Basic shape analysis - this is simplified
    // In a real implementation, you'd use more sophisticated computer vision
    
    if (points.length < 3) return 0;

    // Check for basic letter characteristics
    let score = 50; // Base score

    // Check if the drawing has reasonable proportions
    const bounds = this.getBounds(points);
    const aspectRatio = bounds.width / bounds.height;
    
    // Different letters have different expected aspect ratios
    const expectedRatios = {
      'A': 0.8, 'B': 0.6, 'C': 1.0, 'D': 0.7, 'E': 0.6, 'F': 0.6,
      'G': 0.8, 'H': 0.6, 'I': 0.3, 'J': 0.4, 'K': 0.6, 'L': 0.4,
      'M': 0.8, 'N': 0.6, 'O': 1.0, 'P': 0.6, 'Q': 0.8, 'R': 0.6,
      'S': 0.8, 'T': 0.6, 'U': 0.8, 'V': 0.6, 'W': 0.8, 'X': 0.8,
      'Y': 0.6, 'Z': 0.8
    };

    const expectedRatio = expectedRatios[letter.toUpperCase()] || 0.7;
    const ratioScore = Math.max(0, 100 - Math.abs(aspectRatio - expectedRatio) * 100);
    
    score = (score + ratioScore) / 2;

    return Math.min(100, score);
  }

  getBounds(points) {
    if (points.length === 0) return { width: 0, height: 0 };

    let minX = points[0].x, maxX = points[0].x;
    let minY = points[0].y, maxY = points[0].y;

    points.forEach(point => {
      minX = Math.min(minX, point.x);
      maxX = Math.max(maxX, point.x);
      minY = Math.min(minY, point.y);
      maxY = Math.max(maxY, point.y);
    });

    return {
      width: maxX - minX,
      height: maxY - minY
    };
  }

  calculateXP(score, baseXP) {
    // XP calculation with diminishing returns
    const multiplier = score / 100;
    const xp = Math.floor(baseXP * multiplier);
    return Math.max(1, xp); // Minimum 1 XP
  }
}

module.exports = ScoringService;