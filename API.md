# SkillStreak API Documentation

Base URL: `http://localhost:3000/api`

## Authentication

Currently, the API uses simple user ID-based authentication. In a production environment, you would implement proper JWT or OAuth authentication.

## Rate Limiting

- **Global Rate Limit**: 100 requests per 15 minutes per IP
- **Exercise Validation**: 10 runs per minute per user

## Endpoints

### Health Check

#### GET /health
Check if the server is running.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

---

### Exercise Validation

#### POST /api/exercises/validateRun
Validate an exercise run and return the calculated score.

**Request Body:**
```json
{
  "userId": "string",
  "exerciseType": "trace|count|rhythm",
  "exerciseId": "string", 
  "courseId": "string (optional)",
  "runData": {
    // Exercise-specific data (see below)
  }
}
```

**Trace Exercise runData:**
```json
{
  "tracePoints": [
    {
      "x": 100.5,
      "y": 200.3,
      "timestamp": 1640995200000
    }
  ],
  "templatePoints": [
    {
      "x": 100.0,
      "y": 200.0, 
      "timestamp": 0
    }
  ],
  "timeSpent": 5000
}
```

**Count Exercise runData:**
```json
{
  "userCount": 5,
  "correctCount": 5,
  "timeSpent": 3000
}
```

**Rhythm Exercise runData:**
```json
{
  "taps": [
    {
      "timestamp": 1640995200000,
      "isCorrect": false
    }
  ],
  "expectedTaps": [
    {
      "timestamp": 1640995200000,
      "isCorrect": false
    }
  ],
  "bpm": 60
}
```

**Response:**
```json
{
  "success": true,
  "score": {
    "accuracy": 85.5,
    "xp": 171,
    "multiplier": 1.2,
    "baseScore": 85.5,
    "details": {
      // Exercise-specific scoring details
    }
  }
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Error description"
}
```

#### GET /api/exercises/history/:userId
Get exercise history for a user.

**Query Parameters:**
- `limit` (optional): Number of results (default: 50)
- `offset` (optional): Pagination offset (default: 0)

**Response:**
```json
{
  "success": true,
  "history": [
    {
      "exercise_type": "trace",
      "course_id": "basics-alphabet",
      "exercise_id": "trace-a",
      "score_data": {
        "accuracy": 85.5,
        "xp": 171,
        "details": {}
      },
      "xp_earned": 171,
      "completed_at": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

---

### Courses

#### GET /api/courses
Get all available courses.

**Response:**
```json
{
  "success": true,
  "courses": [
    {
      "id": "basics-alphabet",
      "title": "Alphabet Basics",
      "description": "Learn to trace letters A-Z",
      "unlock_xp": 0,
      "exercises": [
        {
          "id": "trace-a",
          "type": "trace",
          "difficulty": 1,
          "letter": "A"
        }
      ],
      "created_at": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

#### GET /api/courses/:courseId
Get a specific course by ID.

**Response:**
```json
{
  "success": true,
  "course": {
    "id": "basics-alphabet",
    "title": "Alphabet Basics",
    "description": "Learn to trace letters A-Z",
    "unlock_xp": 0,
    "exercises": [...]
  }
}
```

#### GET /api/courses/:courseId/progress/:userId
Get user's progress for a specific course.

**Response:**
```json
{
  "success": true,
  "progress": {
    "completedExercises": ["trace-a", "trace-b"],
    "progressPercent": 40
  }
}
```

#### POST /api/courses/:courseId/progress/:userId
Update user's progress for a course.

**Request Body:**
```json
{
  "exerciseId": "trace-a"
}
```

**Response:**
```json
{
  "success": true,
  "progress": {
    "completedExercises": ["trace-a"],
    "progressPercent": 20
  }
}
```

---

### Leaderboard

#### GET /api/leaderboard
Get the global leaderboard.

**Query Parameters:**
- `limit` (optional): Number of results (default: 50)

**Response:**
```json
{
  "success": true,
  "leaderboard": [
    {
      "rank": 1,
      "user_id": "user-123",
      "username": "TopPlayer",
      "total_xp": 5000,
      "current_streak": 15,
      "last_activity": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

#### GET /api/leaderboard/:userId
Get a specific user's leaderboard stats.

**Response:**
```json
{
  "success": true,
  "userStats": {
    "user_id": "user-123",
    "username": "Player",
    "total_xp": 1500,
    "current_streak": 5,
    "rank": 42,
    "totalUsers": 100,
    "last_activity": "2024-01-01T00:00:00.000Z"
  }
}
```

#### GET /api/leaderboard/stats/global
Get global statistics.

**Response:**
```json
{
  "success": true,
  "globalStats": {
    "totalUsers": 100,
    "avgXP": 750,
    "maxXP": 5000,
    "avgStreak": 3,
    "maxStreak": 15,
    "activeToday": 25,
    "exerciseStats": [
      {
        "exercise_type": "trace",
        "count": 150,
        "avgXP": 85
      }
    ]
  }
}
```

---

## Error Codes

| Code | Description |
|------|-------------|
| 400  | Bad Request - Invalid input data |
| 404  | Not Found - Resource doesn't exist |
| 429  | Too Many Requests - Rate limit exceeded |
| 500  | Internal Server Error - Server-side error |

## Exercise Scoring Details

### Trace Exercise Scoring

The trace scoring algorithm evaluates:

1. **Path Similarity** (60% weight): How closely the user's trace matches the template path
2. **Coverage** (40% weight): What percentage of the template was traced
3. **Speed Penalty**: Penalties for tracing too fast (< 50% ideal time) or too slow (> 300% ideal time)

**Details Object:**
```json
{
  "pathSimilarity": 85.5,
  "coverage": 92.0,
  "speedPenalty": 5.0,
  "timeSpent": 5000,
  "idealTime": 4000
}
```

### Count Exercise Scoring

The count scoring algorithm evaluates:

1. **Accuracy**: Based on how close the guess is to the correct answer
2. **Speed Bonus**: Bonus points for quick accurate answers (< 10 seconds)

**Accuracy Scale:**
- Exact match: 100%
- Off by 1: 85%
- Off by 2: 70%
- Off by more: Scaled based on difference

**Details Object:**
```json
{
  "userCount": 5,
  "correctCount": 5,
  "difference": 0,
  "isExact": true,
  "speedBonus": 8.5,
  "timeSpent": 3000
}
```

### Rhythm Exercise Scoring

The rhythm scoring algorithm evaluates:

1. **Timing Accuracy**: How close taps are to expected timing
2. **Completion Ratio**: Percentage of expected taps that were hit
3. **Penalties**: For missed taps and extra taps

**Tolerance**: 15% of beat interval (e.g., 150ms for 60 BPM)

**Details Object:**
```json
{
  "correctTaps": 8,
  "totalTaps": 10,
  "expectedTaps": 8,
  "timingAccuracy": 88.5,
  "averageOffset": 45,
  "missedTaps": 0,
  "extraTaps": 2,
  "tolerance": 150
}
```

## Webhook Support (Future)

The API is designed to support webhooks for real-time updates:

- User progress updates
- Achievement unlocks
- Leaderboard changes

## SDKs and Libraries

Currently, the API is consumed directly by the Flutter mobile app using the `http` package. Future SDKs may be provided for:

- JavaScript/TypeScript
- Python
- Java/Kotlin
- Swift

## Changelog

### v1.0.0 (Current)
- Initial API release
- Exercise validation endpoints
- Course management
- Leaderboard system
- Basic rate limiting

### Future Versions
- Authentication system
- Webhook support
- Advanced analytics
- Multi-language support