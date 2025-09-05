# SkillStreak API Documentation

## Base URL
```
http://localhost:3000
```

## Authentication
Currently, the API does not require authentication for local development. In production, you would implement proper authentication.

## Endpoints

### Health Check

#### GET /health
Check if the server is running.

**Response:**
```json
{
  "status": "OK",
  "timestamp": "2023-01-01T00:00:00.000Z"
}
```

### Exercise Validation

#### POST /api/validateRun
Validate an exercise run and return the score and XP earned.

**Request Body:**
```json
{
  "exerciseType": "trace|count|rhythm",
  "exerciseId": "string",
  "runData": {
    // Exercise-specific data (see below)
  },
  "score": 0,
  "xpEarned": 10,
  "timestamp": "2023-01-01T00:00:00.000Z",
  "validated": false
}
```

**Trace Exercise Data:**
```json
{
  "points": [
    {"x": 100, "y": 100},
    {"x": 150, "y": 150}
  ],
  "letter": "A",
  "width": 300,
  "height": 300
}
```

**Count Exercise Data:**
```json
{
  "guessedCount": 5,
  "imageId": "apples",
  "boundingBoxes": []
}
```

**Rhythm Exercise Data:**
```json
{
  "tapTimes": [0, 500, 1000, 1500],
  "expectedTimes": [0, 500, 1000, 1500],
  "bpm": 120
}
```

**Response:**
```json
{
  "validated": true,
  "score": 85.5,
  "xpEarned": 8,
  "feedback": "Great job! Very well done!",
  "timestamp": "2023-01-01T00:00:00.000Z",
  "exerciseType": "trace",
  "exerciseId": "trace_a"
}
```

### Courses

#### GET /api/courses
Get all available courses.

**Response:**
```json
[
  {
    "id": "alphabet_basics",
    "title": "Alphabet Basics",
    "description": "Learn to trace basic letters",
    "icon": "🔤",
    "requiredXP": 0,
    "exercises": [
      {
        "id": "trace_a",
        "type": "trace",
        "title": "Trace Letter A",
        "description": "Draw the letter A on the canvas",
        "data": {"letter": "A"},
        "baseXP": 10
      }
    ],
    "unlocked": true
  }
]
```

### Leaderboard

#### GET /api/leaderboard
Get the current leaderboard.

**Response:**
```json
[
  {
    "username": "Alex",
    "avatar": "👨",
    "totalXP": 1250,
    "currentStreak": 15,
    "rank": 1
  },
  {
    "username": "Sarah",
    "avatar": "👩",
    "totalXP": 1180,
    "currentStreak": 12,
    "rank": 2
  }
]
```

#### POST /api/leaderboard
Update the leaderboard with new entries.

**Request Body:**
```json
[
  {
    "username": "Alex",
    "avatar": "👨",
    "totalXP": 1250,
    "currentStreak": 15,
    "rank": 1
  }
]
```

**Response:**
```json
{
  "success": true
}
```

## Error Responses

### 400 Bad Request
```json
{
  "error": "Invalid request data"
}
```

### 404 Not Found
```json
{
  "error": "Route not found"
}
```

### 429 Too Many Requests
```json
{
  "error": "Too many requests from this IP, please try again later."
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error"
}
```

## Rate Limiting

- **Limit**: 100 requests per 15 minutes per IP
- **Headers**: Rate limit information is included in response headers
- **Exceeded**: Returns 429 status with error message

## Data Models

### User
```typescript
interface User {
  id?: number;
  username: string;
  avatar: string;
  totalXP: number;
  currentStreak: number;
  longestStreak: number;
  lastActiveDate: string;
  walletPoints: number;
  unlockedCourses: string[];
  unlockedThemes: string[];
  unlockedBadges: string[];
}
```

### Run
```typescript
interface Run {
  id?: number;
  exerciseType: 'trace' | 'count' | 'rhythm';
  exerciseId: string;
  runData: object;
  score: number;
  xpEarned: number;
  timestamp: string;
  validated: boolean;
}
```

### Course
```typescript
interface Course {
  id: string;
  title: string;
  description: string;
  icon: string;
  requiredXP: number;
  exercises: Exercise[];
  unlocked: boolean;
}
```

### Exercise
```typescript
interface Exercise {
  id: string;
  type: 'trace' | 'count' | 'rhythm';
  title: string;
  description: string;
  data: object;
  baseXP: number;
}
```

## Scoring Algorithm

### Trace Scoring
1. **Point Count**: Minimum points required for letter
2. **Smoothness**: Angle changes between points
3. **Coverage**: How well the drawing fills the canvas
4. **Shape Accuracy**: Geometric analysis of the shape
5. **Complexity**: Letter-specific difficulty multiplier

### Count Scoring
1. **Accuracy**: Exact match = 100%, close = partial score
2. **Bonus**: +20 points for being 1 off
3. **Penalty**: Score decreases with distance from correct answer

### Rhythm Scoring
1. **Timing Tolerance**: 10% of beat interval
2. **Perfect Hits**: Within tolerance = 100%
3. **Good Hits**: Within 2x tolerance = 70%
4. **Misses**: Beyond 2x tolerance = 0%

## Example Usage

### cURL Examples

**Validate a trace run:**
```bash
curl -X POST http://localhost:3000/api/validateRun \
  -H "Content-Type: application/json" \
  -d '{
    "exerciseType": "trace",
    "exerciseId": "trace_a",
    "runData": {
      "points": [{"x": 100, "y": 100}, {"x": 150, "y": 150}],
      "letter": "A",
      "width": 300,
      "height": 300
    },
    "score": 0,
    "xpEarned": 10,
    "timestamp": "2023-01-01T00:00:00.000Z",
    "validated": false
  }'
```

**Get courses:**
```bash
curl http://localhost:3000/api/courses
```

**Get leaderboard:**
```bash
curl http://localhost:3000/api/leaderboard
```

### JavaScript Examples

**Validate a count run:**
```javascript
const response = await fetch('http://localhost:3000/api/validateRun', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    exerciseType: 'count',
    exerciseId: 'count_apples',
    runData: {
      guessedCount: 5,
      imageId: 'apples',
      boundingBoxes: []
    },
    score: 0,
    xpEarned: 20,
    timestamp: new Date().toISOString(),
    validated: false
  })
});

const result = await response.json();
console.log(result);
```

## Testing

### Health Check
```bash
curl http://localhost:3000/health
```

### API Test Suite
```bash
cd backend
npm test
```

### Load Testing
```bash
# Install artillery
npm install -g artillery

# Run load test
artillery quick --count 10 --num 5 http://localhost:3000/api/courses
```