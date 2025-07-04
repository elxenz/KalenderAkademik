import 'package:flutter/material.dart';
import 'package:kalender/app/app.dart';
import 'package:kalender/core/utils/notification_helper.dart';

void main() async {
  // Pastikan binding Flutter sudah siap sebelum menjalankan kode async
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Notification Helper
  await NotificationHelper().initialize();
  
  runApp(const App());
}