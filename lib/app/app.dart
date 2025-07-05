import 'package:flutter/material.dart';
import 'package:kalender/app/config/router/app_router.dart';
import 'package:kalender/app/config/theme/app_theme.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Cara yang benar untuk mendengarkan provider di dalam build method
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Kalender',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          // Tambahkan null check atau nilai default
          themeMode: settings.themeMode ?? ThemeMode.system,
          onGenerateRoute: AppRouter.onGenerateRoute,
          // Rute awal bisa didefinisikan di sini
          initialRoute: AppRouter.calendar,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
