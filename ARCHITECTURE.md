# SkillStreak Architecture Documentation

## Overview

SkillStreak is a gamified micro-learning mobile application built with Flutter and a Node.js backend. The architecture follows a clean, modular design with offline-first capabilities and real-time scoring validation.

## System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │  Node.js API    │    │   SQLite DB     │
│                 │    │                 │    │                 │
│  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │
│  │    UI     │  │    │  │  Routes   │  │    │  │   Users   │  │
│  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │
│  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │
│  │ Services  │◄─┼────┼─►│ Services  │◄─┼────┼─►│  Courses  │  │
│  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │
│  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │
│  │  Models   │  │    │  │Middleware │  │    │  │   Runs    │  │
│  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │
│  ┌───────────┐  │    │                 │    │                 │
│  │  SQLite   │  │    │                 │    │                 │
│  └───────────┘  │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Mobile App Architecture (Flutter)

### Directory Structure
```
mobile/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/                   # Data models
│   │   ├── user.dart
│   │   ├── course.dart
│   │   └── exercise_run.dart
│   ├── services/                 # Business logic
│   │   ├── database_service.dart
│   │   ├── api_service.dart
│   │   ├── user_service.dart
│   │   └── course_service.dart
│   ├── screens/                  # UI screens
│   │   ├── onboarding_screen.dart
│   │   ├── home_screen.dart
│   │   ├── exercise_screen.dart
│   │   └── ...
│   ├── widgets/                  # Reusable UI components
│   │   ├── exercises/
│   │   └── ...
│   └── utils/                    # Utilities and themes
│       └── app_theme.dart
├── assets/                       # Static assets
├── test/                         # Unit tests
└── integration_test/             # Integration tests
```

### Key Components

#### State Management
- **Provider Pattern**: Used for dependency injection and state management
- **ChangeNotifier**: Services extend this for reactive state updates
- **Consumer Widgets**: UI components react to service state changes

#### Data Layer
- **Local SQLite Database**: Primary data storage with sqflite
- **Shared Preferences**: Simple key-value storage for user settings
- **Models**: Immutable data classes with JSON serialization

#### Service Layer
- **DatabaseService**: Local data persistence and queries
- **ApiService**: HTTP communication with backend
- **UserService**: User management and authentication
- **CourseService**: Course and progress management

#### UI Layer
- **Screens**: Full-page UI components
- **Widgets**: Reusable UI components
- **Theme System**: Consistent styling and theming

### Offline-First Design

The app is designed to work offline-first:

1. **Local Storage**: All user data stored locally in SQLite
2. **API Sync**: Optional sync with backend for validation and leaderboards  
3. **Graceful Degradation**: App functions without network connectivity
4. **Local Scoring**: Fallback scoring algorithms when API is unavailable

## Backend Architecture (Node.js)

### Directory Structure
```
backend/
├── src/
│   ├── server.js                 # Express app setup
│   ├── database/
│   │   └── database.js          # SQLite connection and schema
│   ├── routes/                   # API route handlers
│   │   ├── exercises.js
│   │   ├── courses.js
│   │   └── leaderboard.js
│   ├── services/                 # Business logic
│   │   ├── scoringService.js
│   │   └── userService.js
│   ├── middleware/               # Express middleware
│   │   └── errorHandler.js
│   └── data/                     # SQLite database files
├── __tests__/                    # Jest tests
├── Dockerfile                    # Container configuration
└── package.json                  # Dependencies and scripts
```

### Key Components

#### API Layer
- **Express.js**: Web framework for REST API
- **CORS**: Cross-origin request handling
- **Helmet**: Security middleware
- **Rate Limiting**: Request throttling and abuse prevention

#### Business Logic
- **Scoring Service**: Exercise validation and scoring algorithms
- **User Service**: User management and statistics
- **Database Service**: Data access layer

#### Data Layer
- **SQLite**: Lightweight relational database
- **Schema**: Users, courses, exercise runs, progress tracking
- **Migrations**: Database version management

### Scoring Algorithms

#### Trace Exercise Scoring
```javascript
score = (pathSimilarity * 0.6 + coverage * 0.4) - speedPenalty
```

- **Path Similarity**: Dynamic Time Warping approximation
- **Coverage**: Percentage of template points traced
- **Speed Penalty**: Penalties for too fast/slow completion

#### Count Exercise Scoring  
```javascript
baseScore = accuracyBasedOnDifference
finalScore = baseScore + speedBonus
```

- **Accuracy**: Based on difference from correct answer
- **Speed Bonus**: Bonus for quick accurate responses

#### Rhythm Exercise Scoring
```javascript
score = (completionRatio * 0.7 + timingAccuracy * 0.3) - extraTapPenalty
```

- **Timing Accuracy**: Offset from expected tap times
- **Completion Ratio**: Percentage of expected taps hit
- **Penalties**: For missed and extra taps

## Data Models

### User Model
```dart
class User {
  final String id;
  final String username;
  final String? avatarPath;
  final int totalXP;
  final int currentStreak;
  final DateTime? lastActivity;
  final DateTime createdAt;
  final Map<String, dynamic> preferences;
}
```

### Course Model
```dart
class Course {
  final String id;
  final String title;
  final String description;
  final int unlockXP;
  final List<Exercise> exercises;
  final DateTime createdAt;
}
```

### Exercise Run Model
```dart
class ExerciseRun {
  final String? id;
  final String userId;
  final String exerciseType;
  final String? courseId;
  final String exerciseId;
  final Map<String, dynamic> runData;
  final ExerciseScore? score;
  final DateTime completedAt;
}
```

## Database Schema

### Mobile App (SQLite)
```sql
-- Users table
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  username TEXT NOT NULL,
  avatar_path TEXT,
  total_xp INTEGER DEFAULT 0,
  current_streak INTEGER DEFAULT 0,
  last_activity TEXT,
  created_at TEXT NOT NULL,
  preferences TEXT DEFAULT '{}'
);

-- Courses table  
CREATE TABLE courses (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  unlock_xp INTEGER DEFAULT 0,
  exercises TEXT NOT NULL,
  created_at TEXT NOT NULL
);

-- Exercise runs table
CREATE TABLE exercise_runs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  exercise_type TEXT NOT NULL,
  course_id TEXT,
  exercise_id TEXT NOT NULL,
  run_data TEXT NOT NULL,
  score_data TEXT,
  completed_at TEXT NOT NULL
);
```

### Backend (SQLite)
Similar schema with additional tables for leaderboard caching and global statistics.

## Security Considerations

### Current Implementation
- **Rate Limiting**: 100 requests per 15 minutes globally
- **Input Validation**: Joi schema validation for all inputs
- **SQL Injection Prevention**: Parameterized queries
- **CORS Configuration**: Controlled cross-origin access

### Production Recommendations
- **Authentication**: JWT tokens or OAuth 2.0
- **HTTPS Only**: TLS encryption for all communications
- **API Keys**: Rate limiting per authenticated user
- **Data Encryption**: Encrypt sensitive data at rest
- **Audit Logging**: Track all data modifications

## Performance Optimizations

### Mobile App
- **Lazy Loading**: Load course content on demand
- **Image Caching**: Cache exercise assets locally
- **Database Indexing**: Indexes on frequently queried fields
- **Widget Optimization**: Efficient widget rebuilding

### Backend
- **Connection Pooling**: Reuse database connections
- **Response Caching**: Cache frequently requested data
- **Compression**: Gzip compression for API responses
- **Database Optimization**: Proper indexing and query optimization

## Deployment Architecture

### Development
```
Developer Machine
├── Flutter App (flutter run)
├── Backend (npm run dev)
└── SQLite Database (local files)
```

### Production
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile App    │    │  Load Balancer  │    │   Docker Host   │
│   (APK/IPA)     │    │                 │    │                 │
│                 │    │                 │    │  ┌───────────┐  │
│                 │◄───┼─────────────────┼────┼─►│ Backend   │  │
│                 │    │                 │    │  │ Container │  │
│                 │    │                 │    │  └───────────┘  │
└─────────────────┘    └─────────────────┘    │  ┌───────────┐  │
                                              │  │ Database  │  │
                                              │  │  Volume   │  │
                                              │  └───────────┘  │
                                              └─────────────────┘
```

## Testing Strategy

### Mobile App Testing
- **Unit Tests**: Service logic and model validation
- **Widget Tests**: UI component behavior
- **Integration Tests**: End-to-end user flows
- **Golden Tests**: Visual regression testing

### Backend Testing  
- **Unit Tests**: Service and utility functions
- **Integration Tests**: API endpoint testing
- **Load Testing**: Performance under load
- **Security Testing**: Vulnerability scanning

## Monitoring and Analytics

### Planned Monitoring
- **Error Tracking**: Crash reporting and error logging
- **Performance Monitoring**: App performance metrics
- **Usage Analytics**: User behavior and engagement
- **API Monitoring**: Response times and error rates

### Metrics to Track
- **User Engagement**: Daily/monthly active users
- **Exercise Completion**: Success rates by exercise type
- **Performance**: App startup time, API response times
- **Errors**: Crash rates, API error rates

## Future Architecture Considerations

### Scalability
- **Microservices**: Split backend into focused services
- **Database Sharding**: Distribute data across multiple databases
- **CDN**: Content delivery network for static assets
- **Caching Layer**: Redis for session and data caching

### Advanced Features
- **Real-time Updates**: WebSocket connections for live features
- **Machine Learning**: Adaptive difficulty and personalization
- **Multi-platform**: Web and desktop versions
- **Offline Sync**: Robust conflict resolution for offline changes

## Technology Choices Rationale

### Flutter for Mobile
- **Cross-platform**: Single codebase for iOS and Android
- **Performance**: Native performance with Dart compilation
- **UI Flexibility**: Custom UI components and animations
- **Ecosystem**: Rich package ecosystem and tooling

### Node.js for Backend
- **JavaScript Ecosystem**: Large package ecosystem
- **Performance**: Event-driven, non-blocking I/O
- **Development Speed**: Rapid prototyping and development
- **JSON Native**: Natural fit for JSON API responses

### SQLite for Database
- **Simplicity**: No separate database server required
- **Performance**: Fast for read-heavy workloads
- **Portability**: Single file database
- **Reliability**: ACID compliance and crash safety

This architecture provides a solid foundation for the SkillStreak application with room for future growth and optimization.