# SkillStreak Setup Guide

## Quick Start

### Prerequisites
- **Flutter SDK** (3.16.0 or later) - [Download here](https://flutter.dev/docs/get-started/install)
- **Node.js** (18 or later) - [Download here](https://nodejs.org/)
- **Docker & Docker Compose** - [Download here](https://www.docker.com/get-started)
- **Git** - [Download here](https://git-scm.com/)

### 1. Clone the Repository
```bash
git clone <repository-url>
cd skillstreak
```

### 2. Start the Backend
```bash
# Using Docker (Recommended)
docker-compose up -d

# Or manually
cd backend
npm install
npm start
```

The backend will be available at `http://localhost:3000`

### 3. Run the Mobile App
```bash
cd mobile
flutter pub get
flutter run
```

## Detailed Setup

### Backend Setup

1. **Install Dependencies**
   ```bash
   cd backend
   npm install
   ```

2. **Environment Configuration**
   - The backend uses SQLite for local storage
   - Database file will be created automatically at `backend/data/skillstreak.db`
   - No additional configuration required for local development

3. **Run in Development Mode**
   ```bash
   npm run dev  # Uses nodemon for auto-restart
   ```

4. **Run Tests**
   ```bash
   npm test
   ```

### Mobile App Setup

1. **Install Flutter Dependencies**
   ```bash
   cd mobile
   flutter pub get
   ```

2. **Run Tests**
   ```bash
   flutter test
   ```

3. **Build for Android**
   ```bash
   flutter build apk --release
   ```

4. **Build for iOS** (macOS only)
   ```bash
   flutter build ios --release
   ```

### Docker Setup

1. **Build and Run Backend**
   ```bash
   docker-compose up -d
   ```

2. **View Logs**
   ```bash
   docker-compose logs -f backend
   ```

3. **Stop Services**
   ```bash
   docker-compose down
   ```

## Project Structure

```
skillstreak/
├── mobile/                    # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart         # App entry point
│   │   ├── models/           # Data models
│   │   ├── services/         # API and database services
│   │   ├── screens/          # UI screens
│   │   └── widgets/          # Reusable widgets
│   ├── test/                 # Flutter tests
│   ├── android/              # Android configuration
│   ├── ios/                  # iOS configuration
│   └── pubspec.yaml          # Flutter dependencies
├── backend/                   # Node.js backend
│   ├── src/
│   │   ├── controllers/      # API controllers
│   │   ├── models/           # Data models
│   │   ├── routes/           # API routes
│   │   ├── services/         # Business logic
│   │   └── utils/            # Utility functions
│   ├── tests/                # Backend tests
│   ├── data/                 # SQLite database
│   └── package.json          # Node.js dependencies
├── docker-compose.yml        # Docker configuration
├── Dockerfile               # Backend Docker image
└── .github/workflows/       # CI/CD pipeline
```

## API Endpoints

### Health Check
- `GET /health` - Server health status

### Exercise Validation
- `POST /api/validateRun` - Validate exercise runs and return scores

### Courses
- `GET /api/courses` - Get available courses

### Leaderboard
- `GET /api/leaderboard` - Get local leaderboard
- `POST /api/leaderboard` - Update leaderboard

## Game Features

### Exercise Types

1. **Trace Letters**
   - Draw letters on canvas
   - Backend validates similarity to template
   - Scoring based on smoothness, coverage, and shape accuracy

2. **Count Objects**
   - Count objects in images
   - Backend validates accuracy
   - Scoring based on correctness

3. **Rhythm Tap**
   - Tap along with beat patterns
   - Backend validates timing accuracy
   - Scoring based on timing precision

### Scoring System

- **XP Calculation**: `floor(accuracy_percent * baseXP / 100)`
- **Streak System**: Consecutive days increase multiplier
- **Unlocks**: Courses unlock at XP thresholds
- **Wallet**: Points for cosmetic unlocks

### Anti-Cheat

- Backend validates all runs
- Rate limiting on API endpoints
- Data integrity checks
- Suspicious pattern detection

## Troubleshooting

### Common Issues

1. **Flutter Doctor Issues**
   ```bash
   flutter doctor
   flutter doctor --android-licenses
   ```

2. **Backend Connection Issues**
   - Check if backend is running on port 3000
   - Verify CORS settings in backend
   - Check network connectivity

3. **Database Issues**
   - Delete `backend/data/skillstreak.db` to reset
   - Check file permissions

4. **Docker Issues**
   ```bash
   docker-compose down -v  # Remove volumes
   docker-compose up --build  # Rebuild images
   ```

### Development Tips

1. **Hot Reload**: Use `flutter run` for hot reload during development
2. **API Testing**: Use tools like Postman or curl to test API endpoints
3. **Database Inspection**: Use SQLite browser to inspect the database
4. **Logs**: Check both Flutter and Node.js logs for debugging

## Production Deployment

### Backend Deployment

1. **Docker Production**
   ```bash
   docker build -t skillstreak-backend .
   docker run -p 3000:3000 skillstreak-backend
   ```

2. **Environment Variables**
   - Set `NODE_ENV=production`
   - Configure database connection
   - Set up proper logging

### Mobile App Deployment

1. **Android**
   ```bash
   flutter build apk --release
   # Upload to Google Play Store
   ```

2. **iOS**
   ```bash
   flutter build ios --release
   # Upload to App Store
   ```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details