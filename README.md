# SkillStreak - Gamified Micro-Learning App

A complete Flutter + Node.js project for gamified micro-learning with offline-first architecture.

## Project Structure

```
skillstreak/
├── mobile/                    # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── services/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── utils/
│   ├── test/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
├── backend/                   # Node.js backend
│   ├── src/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── services/
│   │   └── utils/
│   ├── tests/
│   ├── data/
│   ├── package.json
│   └── server.js
├── docker-compose.yml
├── Dockerfile
├── .github/workflows/ci.yml
└── README.md
```

## Quick Start

### Prerequisites
- Flutter SDK (stable channel)
- Node.js 18+
- Docker & Docker Compose

### Backend Setup
```bash
cd backend
docker-compose up -d
```

### Mobile App Setup
```bash
cd mobile
flutter pub get
flutter run
```

## Features

- **Trace Letter**: Draw letters on canvas with similarity scoring
- **Count Objects**: Count objects in images with accuracy validation
- **Rhythm Tap**: Tap along with beats with timing validation
- **Streak System**: Consecutive day multipliers
- **XP & Unlocks**: Experience points and course progression
- **Local Leaderboard**: SQLite-based offline leaderboard
- **Offline-First**: All data stored locally

## API Endpoints

- `POST /api/validateRun` - Validate exercise runs and return scores
- `GET /api/courses` - Get available courses
- `GET /api/leaderboard` - Get local leaderboard
- `POST /api/user` - Create/update user profile

## Testing

```bash
# Backend tests
cd backend && npm test

# Flutter tests
cd mobile && flutter test
```

## Docker

```bash
docker-compose up -d
```

The backend will be available at `http://localhost:3000`