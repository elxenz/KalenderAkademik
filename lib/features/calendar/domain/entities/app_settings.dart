import 'package:flutter/material.dart';

class AppSettings {
  final ThemeMode themeMode;
  final int defaultNotificationTime; // dalam menit

  AppSettings({
    this.themeMode = ThemeMode.system,
    this.defaultNotificationTime = 10,
  });
}
