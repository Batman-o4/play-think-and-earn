import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillstreak/services/database_service.dart';
import 'package:skillstreak/services/api_service.dart';
import 'package:skillstreak/services/user_service.dart';
import 'package:skillstreak/services/course_service.dart';
import 'package:skillstreak/screens/onboarding_screen.dart';
import 'package:skillstreak/screens/home_screen.dart';
import 'package:skillstreak/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final databaseService = DatabaseService();
  await databaseService.initialize();
  
  runApp(SkillStreakApp(databaseService: databaseService));
}

class SkillStreakApp extends StatelessWidget {
  final DatabaseService databaseService;
  
  const SkillStreakApp({
    Key? key,
    required this.databaseService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        ChangeNotifierProxyProvider<DatabaseService, UserService>(
          create: (context) => UserService(databaseService),
          update: (context, database, previous) => 
              previous ?? UserService(database),
        ),
        ChangeNotifierProxyProvider2<DatabaseService, ApiService, CourseService>(
          create: (context) => CourseService(
            databaseService, 
            context.read<ApiService>(),
          ),
          update: (context, database, api, previous) => 
              previous ?? CourseService(database, api),
        ),
      ],
      child: MaterialApp(
        title: 'SkillStreak',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AppInitializer(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final userService = context.read<UserService>();
    await userService.loadCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        if (userService.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading SkillStreak...',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          );
        }

        if (userService.currentUser == null) {
          return const OnboardingScreen();
        }

        return const HomeScreen();
      },
    );
  }
}