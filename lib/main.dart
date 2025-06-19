import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:apex_money/src/routes/app_router.dart';
import 'package:apex_money/src/features/groups/presentation/providers/groups_provider.dart';
import 'package:apex_money/src/shared/theme/app_theme.dart';
import 'package:apex_money/src/shared/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the app to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(MyApp(themeProvider: themeProvider));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  
  const MyApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => GroupsProvider()),
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
