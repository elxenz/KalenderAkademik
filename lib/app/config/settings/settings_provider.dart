import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  int _defaultNotificationTime = 10; // Default 10 menit

  ThemeMode get themeMode => _themeMode;
  int get defaultNotificationTime => _defaultNotificationTime;

  SettingsProvider() {
    _loadSettings();
  }

  // Muat semua pengaturan dari SharedPreferences
  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 0;
    _themeMode = ThemeMode.values[themeIndex];

    _defaultNotificationTime = prefs.getInt('notificationTime') ?? 10;

    notifyListeners();
  }

  // Fungsi untuk mengubah dan menyimpan tema
  void setTheme(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;
    _themeMode = themeMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', _themeMode.index);
    notifyListeners();
  }

  // Fungsi untuk mengubah dan menyimpan waktu notifikasi
  void setNotificationTime(int minutes) async {
    if (_defaultNotificationTime == minutes) return;
    _defaultNotificationTime = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notificationTime', minutes);
    notifyListeners();
  }
}
