/**
 * Scoring algorithms for different exercise types
 */

/**
 * Calculate trace exercise score based on path similarity
 * @param {Object} runData - Contains tracePoints, templatePoints, timeSpent
 * @returns {Object} Score result with accuracy and details
 */
function calculateTraceScore(runData) {
  const { tracePoints, templatePoints, timeSpent } = runData;
  
  if (!tracePoints || !templatePoints || tracePoints.length === 0) {
    return {
      accuracy: 0,
      details: {
        pathSimilarity: 0,
        speedPenalty: 0,
        coverage: 0
      }
    };
  }

  // Normalize points to 0-1 range for comparison
  const normalizePoints = (points) => {
    if (points.length === 0) return [];
    
    const minX = Math.min(...points.map(p => p.x));
    const maxX = Math.max(...points.map(p => p.x));
    const minY = Math.min(...points.map(p => p.y));
    const maxY = Math.max(...points.map(p => p.y));
    
    const width = maxX - minX || 1;
    const height = maxY - minY || 1;
    
    return points.map(p => ({
      x: (p.x - minX) / width,
      y: (p.y - minY) / height
    }));
  };

  const normalizedTrace = normalizePoints(tracePoints);
  const normalizedTemplate = normalizePoints(templatePoints);

  // Calculate path similarity using dynamic time warping approximation
  let totalDistance = 0;
  let comparisons = 0;

  for (let i = 0; i < normalizedTrace.length; i++) {
    const tracePoint = normalizedTrace[i];
    let minDistance = Infinity;
    
    // Find closest template point
    for (let j = 0; j < normalizedTemplate.length; j++) {
      const templatePoint = normalizedTemplate[j];
      const distance = Math.sqrt(
        Math.pow(tracePoint.x - templatePoint.x, 2) + 
        Math.pow(tracePoint.y - templatePoint.y, 2)
      );
      minDistance = Math.min(minDistance, distance);
    }
    
    totalDistance += minDistance;
    comparisons++;
  }

  const averageDistance = comparisons > 0 ? totalDistance / comparisons : 1;
  const pathSimilarity = Math.max(0, 100 - (averageDistance * 200)); // Scale to 0-100

  // Calculate coverage (how much of template was traced)
  let coveredPoints = 0;
  const threshold = 0.1; // 10% of normalized space
  
  for (const templatePoint of normalizedTemplate) {
    const isCovered = normalizedTrace.some(tracePoint => 
      Math.sqrt(
        Math.pow(tracePoint.x - templatePoint.x, 2) + 
        Math.pow(tracePoint.y - templatePoint.y, 2)
      ) <= threshold
    );
    if (isCovered) coveredPoints++;
  }
  
  const coverage = (coveredPoints / normalizedTemplate.length) * 100;

  // Speed penalty (too fast or too slow)
  const idealTime = Math.max(2000, templatePoints.length * 50); // 50ms per point minimum
  const speedRatio = timeSpent / idealTime;
  let speedPenalty = 0;
  
  if (speedRatio < 0.5) {
    speedPenalty = (0.5 - speedRatio) * 20; // Penalty for being too fast
  } else if (speedRatio > 3) {
    speedPenalty = (speedRatio - 3) * 5; // Smaller penalty for being slow
  }

  // Combine scores
  const baseAccuracy = (pathSimilarity * 0.6) + (coverage * 0.4);
  const finalAccuracy = Math.max(0, Math.min(100, baseAccuracy - speedPenalty));

  return {
    accuracy: Math.round(finalAccuracy * 100) / 100,
    details: {
      pathSimilarity: Math.round(pathSimilarity * 100) / 100,
      coverage: Math.round(coverage * 100) / 100,
      speedPenalty: Math.round(speedPenalty * 100) / 100,
      timeSpent,
      idealTime
    }
  };
}

/**
 * Calculate count exercise score based on accuracy
 * @param {Object} runData - Contains userCount, correctCount, timeSpent
 * @returns {Object} Score result with accuracy and details
 */
function calculateCountScore(runData) {
  const { userCount, correctCount, timeSpent } = runData;
  
  if (typeof userCount !== 'number' || typeof correctCount !== 'number') {
    return {
      accuracy: 0,
      details: {
        difference: 0,
        isExact: false,
        speedBonus: 0
      }
    };
  }

  const difference = Math.abs(userCount - correctCount);
  const maxDifference = Math.max(correctCount, 10); // Allow for reasonable margin
  
  // Base accuracy based on how close the guess was
  let baseAccuracy;
  if (difference === 0) {
    baseAccuracy = 100; // Perfect
  } else if (difference === 1) {
    baseAccuracy = 85; // Very close
  } else if (difference <= 2) {
    baseAccuracy = 70; // Close
  } else {
    baseAccuracy = Math.max(0, 100 - ((difference / maxDifference) * 100));
  }

  // Speed bonus (reward quick accurate answers)
  let speedBonus = 0;
  if (difference <= 1 && timeSpent < 10000) { // Less than 10 seconds and accurate
    speedBonus = Math.max(0, 15 - (timeSpent / 1000)); // Up to 15 point bonus
  }

  const finalAccuracy = Math.min(100, baseAccuracy + speedBonus);

  return {
    accuracy: Math.round(finalAccuracy * 100) / 100,
    details: {
      userCount,
      correctCount,
      difference,
      isExact: difference === 0,
      speedBonus: Math.round(speedBonus * 100) / 100,
      timeSpent
    }
  };
}

/**
 * Calculate rhythm exercise score based on timing accuracy
 * @param {Object} runData - Contains taps, expectedTaps, bpm
 * @returns {Object} Score result with accuracy and details
 */
function calculateRhythmScore(runData) {
  const { taps, expectedTaps, bpm } = runData;
  
  if (!taps || !expectedTaps || taps.length === 0 || expectedTaps.length === 0) {
    return {
      accuracy: 0,
      details: {
        timingAccuracy: 0,
        missedTaps: 0,
        extraTaps: 0,
        averageOffset: 0
      }
    };
  }

  const beatInterval = 60000 / bpm; // milliseconds per beat
  const tolerance = beatInterval * 0.15; // 15% tolerance

  let correctTaps = 0;
  let totalOffset = 0;
  let matchedTaps = 0;

  // For each expected tap, find the closest user tap
  const usedTapIndices = new Set();
  
  for (const expectedTap of expectedTaps) {
    let closestTapIndex = -1;
    let closestDistance = Infinity;
    
    for (let i = 0; i < taps.length; i++) {
      if (usedTapIndices.has(i)) continue;
      
      const distance = Math.abs(taps[i].timestamp - expectedTap.timestamp);
      if (distance < closestDistance && distance <= tolerance) {
        closestDistance = distance;
        closestTapIndex = i;
      }
    }
    
    if (closestTapIndex !== -1) {
      correctTaps++;
      totalOffset += closestDistance;
      matchedTaps++;
      usedTapIndices.add(closestTapIndex);
    }
  }

  // Calculate accuracy components
  const completionRatio = correctTaps / expectedTaps.length;
  const averageOffset = matchedTaps > 0 ? totalOffset / matchedTaps : tolerance;
  const timingAccuracy = Math.max(0, 100 - ((averageOffset / tolerance) * 100));
  
  // Penalties
  const missedTaps = expectedTaps.length - correctTaps;
  const extraTaps = taps.length - correctTaps;
  const extraTapPenalty = extraTaps * 5; // 5 points per extra tap
  
  // Final score
  const baseScore = (completionRatio * 0.7 + (timingAccuracy / 100) * 0.3) * 100;
  const finalAccuracy = Math.max(0, baseScore - extraTapPenalty);

  return {
    accuracy: Math.round(finalAccuracy * 100) / 100,
    details: {
      correctTaps,
      totalTaps: taps.length,
      expectedTaps: expectedTaps.length,
      timingAccuracy: Math.round(timingAccuracy * 100) / 100,
      averageOffset: Math.round(averageOffset),
      missedTaps,
      extraTaps,
      tolerance: Math.round(tolerance)
    }
  };
}

module.exports = {
  calculateTraceScore,
  calculateCountScore,
  calculateRhythmScore
};