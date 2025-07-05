import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/app_settings.dart';

abstract class SettingsLocalDataSource {
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  @override
  Future<AppSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 0;
    final notificationTime = prefs.getInt('notificationTime') ?? 10;

    return AppSettings(
      themeMode: ThemeMode.values[themeIndex],
      defaultNotificationTime: notificationTime,
    );
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', settings.themeMode.index);
    await prefs.setInt('notificationTime', settings.defaultNotificationTime);
  }
}
