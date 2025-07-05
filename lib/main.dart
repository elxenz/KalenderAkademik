import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kalender/app/app.dart';
import 'package:kalender/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:kalender/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:kalender/features/settings/presentation/provider/settings_provider.dart';
import 'package:kalender/core/utils/notification_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationHelper().initialize();

  final settingsRepository = SettingsRepositoryImpl(
    localDataSource: SettingsLocalDataSourceImpl(),
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) =>
          SettingsProvider(settingsRepository: settingsRepository),
      child: const App(),
    ),
  );
}
