import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/currency_service.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/capture_constants.dart';
import 'core/di/database_provider.dart';
import 'shared/widgets/app_alert_host.dart';
import 'features/auto_capture/data/services/capture_preferences_service.dart';
import 'features/auto_capture/data/services/auto_capture_scheduler.dart';
import 'features/backup/data/services/auto_backup_scheduler.dart';
import 'features/backup/data/services/backup_preferences_service.dart';
import 'features/navigation/presentation/views/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        capturePreferencesServiceProvider.overrideWithValue(
          CapturePreferencesService(prefs),
        ),
      ],
      child: const FynzaApp(),
    ),
  );

  // Initialize background tasks without blocking initial frame rendering
  try {
    final scheduler = AutoBackupScheduler(BackupPreferencesService(prefs));
    await scheduler.initialize();
    if (CaptureConstants.isEnabled) {
      await AutoCaptureScheduler.registerPeriodicDrain();
    }
  } catch (e) {
    debugPrint('Background task initialization failed: ${e.runtimeType}');
  }
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
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [child ?? const SizedBox.shrink(), const AppAlertHost()],
      ),
      home: const MainScaffold(),
    );
  }
}
