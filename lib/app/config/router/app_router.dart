import 'package:flutter/material.dart';
import 'package:kalender/features/calendar/presentation/screens/calendar_screen.dart';

class AppRouter {
  static const Widget initialRoute = CalendarScreen();

  // Nanti Anda bisa menambahkan rute lain di sini
  // static Route<dynamic> generateRoute(RouteSettings settings) {
  //   switch (settings.name) {
  //     case '/calendar':
  //       return MaterialPageRoute(builder: (_) => CalendarScreen());
  //     default:
  //       return MaterialPageRoute(builder: (_) => Text('Halaman tidak ditemukan'));
  //   }
  // }
}