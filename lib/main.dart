import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/currency_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auto_capture/data/services/capture_preferences_service.dart';
import 'features/backup/data/services/auto_backup_scheduler.dart';
import 'features/backup/data/services/backup_preferences_service.dart';
import 'features/navigation/presentation/views/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final scheduler = AutoBackupScheduler(BackupPreferencesService(prefs));
  await scheduler.initialize();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        capturePreferencesServiceProvider
            .overrideWithValue(CapturePreferencesService(prefs)),
      ],
      child: const FynzaApp(),
    ),
  );
}

class FynzaApp extends StatelessWidget {
  const FynzaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fynza',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainScaffold(),
    );
  }
}
