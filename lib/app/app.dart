import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kalender/app/config/router/app_router.dart';
import 'package:kalender/app/config/theme/app_theme.dart';
import 'package:kalender/app/config/settings/settings_provider.dart'; // Ganti impor

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Dengarkan perubahan dari SettingsProvider
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'Kalender',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode:
          settingsProvider.themeMode, // Gunakan themeMode dari provider baru
      home: AppRouter.initialRoute,
    );
  }
}
