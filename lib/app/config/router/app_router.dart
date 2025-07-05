import 'package:flutter/material.dart';
import 'package:kalender/features/calendar/presentation/screens/calendar_screen.dart';
// Pastikan file ini ada dan berisi kelas 'SettingsScreen'
import 'package:kalender/features/settings/presentation/screens/settings_screen.dart';

class AppRouter {
  static const String calendar = '/';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case calendar:
        return MaterialPageRoute(builder: (_) => const CalendarScreen());
      case settings:
        // Panggil sebagai constructor, bukan fungsi
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Halaman tidak ditemukan: ${routeSettings.name}'),
            ),
          ),
        );
    }
  }
}
