import 'package:flutter/material.dart';
import 'package:kalender/app/app.dart';
import 'package:kalender/core/utils/notification_helper.dart';
import 'package:kalender/features/calendar/data/datasources/event_local_datasource.dart';
import 'package:kalender/features/calendar/data/repositories/event_repository_impl.dart';
import 'package:kalender/features/calendar/domain/repositories/event_repository.dart';
import 'package:kalender/features/calendar/presentation/provider/event_provider.dart';
import 'package:kalender/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:kalender/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:kalender/features/settings/domain/repositories/settings_repository.dart';
import 'package:kalender/features/settings/presentation/provider/settings_provider.dart';
import 'package:provider/provider.dart';
// Impor yang benar untuk shared_preferences
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  // 1. Inisialisasi Binding
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Database dan DataSource
  final database = openDatabase(
    join(await getDatabasesPath(), 'calendar_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE events(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, description TEXT, date TEXT, startTime TEXT, endTime TEXT, colorValue INTEGER)',
      );
    },
    version: 1,
  );
  final eventLocalDataSource = EventLocalDataSourceImpl(database: database);

  // 3. Inisialisasi SharedPreferences dan DataSource lainnya
  final prefs = await SharedPreferences.getInstance();
  final settingsLocalDataSource = SettingsLocalDataSourceImpl(prefs: prefs);

  // 4. Inisialisasi Repositori
  final eventRepository =
      EventRepositoryImpl(localDataSource: eventLocalDataSource);
  final settingsRepository =
      SettingsRepositoryImpl(localDataSource: settingsLocalDataSource);

  // 5. Inisialisasi Notification Helper
  final notificationHelper = NotificationHelper();
  await notificationHelper.init();

  runApp(
    // 6. Sediakan semua provider yang dibutuhkan
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(settingsRepository)..loadSettings(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              EventProvider(eventRepository: eventRepository)..getEvents(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
