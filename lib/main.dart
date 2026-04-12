// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'services/app_state.dart';
import 'screens/log_screen.dart';
import 'app_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp(
      title: 'QSOLog',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.get(themeId),
      home: const LogScreen(),
    );
  }
}
