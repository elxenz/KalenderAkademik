import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kalender/app/config/router/app_router.dart';
import 'package:kalender/app/config/theme/app_theme.dart';
import 'package:kalender/features/settings/presentation/provider/settings_provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'Kalender',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsProvider.isLoading
          ? ThemeMode.system
          : settingsProvider.settings.themeMode,
      home: AppRouter.initialRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
