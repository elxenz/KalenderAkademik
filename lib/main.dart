import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kalender/app/app.dart';
import 'package:kalender/app/config/settings/settings_provider.dart'; // Ganti impor
import 'package:kalender/core/utils/notification_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationHelper().initialize();

  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsProvider(), // Gunakan SettingsProvider
      child: const App(),
    ),
  );
}
