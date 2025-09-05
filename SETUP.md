# SkillStreak Setup Guide

This guide will help you set up and run the complete SkillStreak project locally.

## Prerequisites

### Required Software
- **Flutter SDK** (3.16.0 or later, stable channel)
- **Node.js** (18.x or later)
- **Docker** and **Docker Compose**
- **Git**

### Optional (for development)
- **Android Studio** or **VS Code** with Flutter extensions
- **Postman** or similar API testing tool

## Quick Start (5 minutes)

### 1. Clone the Repository
```bash
git clone <repository-url>
cd skillstreak
```

### 2. Start the Backend
```bash
cd backend
docker-compose up -d
```

The backend will be available at `http://localhost:3000`

### 3. Run the Mobile App
```bash
cd mobile
flutter pub get
flutter run
```

That's it! The app should now be running on your device/emulator.

## Detailed Setup

### Backend Setup

#### Option 1: Docker (Recommended)
```bash
cd backend
docker-compose up -d
```

#### Option 2: Local Development
```bash
cd backend
npm install
npm run dev
```

### Mobile App Setup

#### Install Dependencies
```bash
cd mobile
flutter pub get
```

#### Run on Different Platforms
```bash
# Android
flutter run

# iOS (macOS only)
flutter run -d ios

# Web (for testing UI only)
flutter run -d chrome
```

## Verification

### Backend Health Check
```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### Test API Endpoints
```bash
# Get courses
curl http://localhost:3000/api/courses

# Get leaderboard  
curl http://localhost:3000/api/leaderboard
```

### Flutter App Tests
```bash
cd mobile
flutter test
flutter test integration_test/
```

## Development Workflow

### Backend Development
```bash
cd backend
npm run dev    # Start with auto-reload
npm test       # Run tests
npm run test:watch  # Run tests in watch mode
```

### Mobile Development
```bash
cd mobile
flutter run --hot-reload    # Development with hot reload
flutter test --watch        # Run tests in watch mode
flutter analyze             # Static analysis
```

## Troubleshooting

### Common Issues

#### Backend won't start
- Check if port 3000 is available: `lsof -i :3000`
- Verify Docker is running: `docker --version`
- Check logs: `docker-compose logs backend`

#### Flutter app won't build
- Check Flutter installation: `flutter doctor`
- Clean and rebuild: `flutter clean && flutter pub get`
- Check device connection: `flutter devices`

#### Database issues
- Reset database: `docker-compose down -v && docker-compose up -d`
- Check database file permissions in `backend/src/data/`

#### Network connectivity
- Ensure backend is accessible from mobile device
- For Android emulator, use `10.0.2.2:3000` instead of `localhost:3000`
- For iOS simulator, `localhost:3000` should work

### Debug Mode

#### Enable Backend Debug Logs
```bash
cd backend
DEBUG=* npm run dev
```

#### Flutter Debug Mode
```bash
cd mobile
flutter run --debug
flutter logs  # View device logs
```

## Configuration

### Backend Configuration
Edit `backend/src/server.js` to modify:
- Port number (default: 3000)
- Database path
- Rate limiting settings
- CORS settings

### Mobile App Configuration
Edit `mobile/lib/services/api_service.dart` to modify:
- Backend URL (default: http://localhost:3000)
- Timeout settings
- Retry logic

## Production Deployment

### Backend Production
```bash
cd backend
docker build -t skillstreak-backend .
docker run -p 3000:3000 skillstreak-backend
```

### Mobile App Release
```bash
cd mobile
flutter build apk --release          # Android APK
flutter build appbundle --release    # Android App Bundle
flutter build ios --release          # iOS (macOS only)
```

## Next Steps

1. **Customize the App**: Modify themes, colors, and branding in `mobile/lib/utils/app_theme.dart`

2. **Add More Exercises**: Create new exercise types by extending the existing exercise widgets

3. **Enhance Scoring**: Improve the scoring algorithms in `backend/src/services/scoringService.js`

4. **Add Analytics**: Implement user analytics and progress tracking

5. **Deploy to Cloud**: Set up production deployment on your preferred cloud platform

## Getting Help

- Check the [API Documentation](API.md) for backend endpoints
- Review the [Architecture Documentation](ARCHITECTURE.md) for system design
- Open an issue on GitHub for bugs or feature requests

## License

This project is licensed under the MIT License - see the LICENSE file for details.