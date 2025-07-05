import 'package:flutter/material.dart';
import 'package:kalender/features/calendar/presentation/screens/calendar_screen.dart';

class AppRouter {
  // Hapus 'const' karena CalendarScreen tidak lagi const
  static const Widget initialRoute = CalendarScreen();
}
