import 'package:flutter/material.dart';
import 'package:kalender/app/config/router/app_router.dart';
import 'package:kalender/app/config/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalender',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Menggunakan tema sesuai pengaturan sistem
      home: AppRouter.initialRoute,
    );
  }
}
