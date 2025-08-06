import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:apex_money/src/routes/app_router.dart';
// GROUPS FUNCTIONALITY COMMENTED OUT
// import 'package:apex_money/src/features/groups/presentation/providers/groups_provider.dart';
import 'package:apex_money/src/shared/theme/app_theme.dart';
import 'package:apex_money/src/shared/theme/theme_provider.dart';
import 'package:apex_money/src/shared/services/performance_service.dart';
import 'package:apex_money/src/shared/services/haptic_service.dart';
import 'package:apex_money/src/shared/providers/notification_provider.dart';
import 'package:apex_money/src/shared/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load();
  } catch (e) {
    print('Warning: Could not load .env file: $e');
  }

  try {
    // Initialize performance service for startup optimization
    final performanceService = PerformanceService();
    await performanceService.initialize();
    await performanceService.optimizeStartup();
  } catch (e) {
    print('Warning: Performance service initialization failed: $e');
  }

  try {
    // Initialize haptic service
    HapticService();
  } catch (e) {
    print('Warning: Haptic service initialization failed: $e');
  }

  // Lock the app to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  // Initialize notification provider with error handling
  final notificationProvider = NotificationProvider();
  try {
    await notificationProvider.initialize();
  } catch (e) {
    print('Warning: Notification provider initialization failed: $e');
  }

  // Initialize notification service with error handling
  try {
    final notificationService = NotificationService();
    await notificationService.initialize(notificationProvider);
  } catch (e) {
    print('Warning: Notification service initialization failed: $e');
  }

  runApp(
    MyApp(
      themeProvider: themeProvider,
      notificationProvider: notificationProvider,
    ),
  );
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  final NotificationProvider notificationProvider;

  const MyApp({
    super.key,
    required this.themeProvider,
    required this.notificationProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: notificationProvider),
        // GROUPS PROVIDER COMMENTED OUT
        // ChangeNotifierProvider(create: (_) => GroupsProvider()),
        // Add other providers here as needed
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'Apex Money',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
