# SkillStreak - Gamified Micro-Learning App

A complete Flutter mobile app with Node.js backend for gamified micro-learning exercises.

## Project Structure

```
skillstreak/
├── mobile/                 # Flutter mobile app
├── backend/               # Node.js Express API server
├── docker-compose.yml     # Docker setup
├── .github/               # CI/CD workflows
└── README.md             # This file
```

## Features

- **Three Exercise Types:**
  - Trace Letter: Draw letters on canvas with similarity scoring
  - Count Objects: Count objects in images with accuracy validation
  - Rhythm Tap: Tap along with beats with timing validation

- **Game Mechanics:**
  - Streak system with multipliers
  - XP-based progression
  - Course unlocking system
  - Local wallet and cosmetic unlocks
  - Local leaderboard

- **Technical:**
  - Offline-first architecture
  - SQLite local storage
  - REST API backend validation
  - Anti-cheat measures
  - Comprehensive testing

## Quick Start

### Prerequisites
- Flutter SDK (stable channel)
- Node.js 18+
- Docker & Docker Compose

### Run the Backend
```bash
cd backend
docker-compose up -d
```

### Run the Mobile App
```bash
cd mobile
flutter pub get
flutter run
```

## Development Setup

### Backend Development
```bash
cd backend
npm install
npm run dev
```

### Mobile Development
```bash
cd mobile
flutter pub get
flutter test
flutter run
```

## Testing

### Run All Tests
```bash
# Backend tests
cd backend && npm test

# Mobile tests
cd mobile && flutter test
```

## API Documentation

### Endpoints

#### POST /api/validateRun
Validates exercise run and returns verified score.

**Request:**
```json
{
  "exerciseType": "trace|count|rhythm",
  "userId": "string",
  "runData": {
    // Exercise-specific data
  }
}
```

**Response:**
```json
{
  "success": true,
  "score": {
    "accuracy": 85.5,
    "xp": 171,
    "multiplier": 1.2
  }
}
```

#### GET /api/courses
Returns available courses and unlock requirements.

#### GET /api/leaderboard
Returns local leaderboard data.

## Architecture

### Mobile App (Flutter)
- **State Management:** Provider pattern
- **Local Storage:** SQLite via sqflite
- **Networking:** http package for API calls
- **Canvas Drawing:** CustomPainter for trace exercises
- **Audio:** audioplayers for rhythm exercises

### Backend (Node.js)
- **Framework:** Express.js
- **Database:** SQLite3
- **Scoring:** Custom algorithms for each exercise type
- **Validation:** Rate limiting and anti-cheat measures

## License

MIT License - see LICENSE file for details.