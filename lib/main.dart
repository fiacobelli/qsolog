// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'services/app_state.dart';
import 'screens/log_screen.dart';
import 'app_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure the app draws behind the status bar on Android but
  // lets Flutter handle the insets correctly so the AppBar is not hidden.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  await DatabaseService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..initialize(),
      child: const QsoLogApp(),
    ),
  );
}

class QsoLogApp extends StatelessWidget {
  const QsoLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeId = context.watch<AppState>().appTheme;
    final theme = AppThemes.get(themeId);

    return MaterialApp(
      title: 'QSOLog',
      debugShowCheckedModeBanner: false,
      theme: theme.copyWith(
        // Ensure AppBar always accounts for the status bar height on Android.
        // toolbarHeight controls the content area; the status bar padding is
        // added automatically by Scaffold when this is set correctly.
        appBarTheme: theme.appBarTheme.copyWith(
          toolbarHeight: kToolbarHeight,
          scrolledUnderElevation: 0,
        ),
      ),
      home: const LogScreen(),
    );
  }
}
