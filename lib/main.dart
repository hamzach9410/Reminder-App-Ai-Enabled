import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'core/location/geofence_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/queue_service.dart';
import 'data/repositories/reminder_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'presentation/viewmodels/reminder_viewmodel.dart';
import 'presentation/viewmodels/theme_viewmodel.dart';
import 'core/services/api_service.dart';
import 'core/services/speech_service.dart';
import 'core/services/calendar_service.dart';
import 'core/services/fingerprint_service.dart';
import 'core/services/encryption_service.dart';
import 'core/utils/logger.dart';
import 'package:easy_localization/easy_localization.dart';
import 'main_app.dart';

const backgroundTaskName = "com.Autonomousreminder.queue_worker";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final storageService = await StorageService.init();
      final notificationService = NotificationService.instance;
      await notificationService.initialize();
      
      final apiService = ApiService();
      final reminderRepository = ReminderRepository(storageService, apiService);
      
      final queueService = QueueService(reminderRepository, notificationService);
      await queueService.processQueue();
      
      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

/// Entry point of the application
/// Handles initialization of core services
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kDebugMode,
  );

  // Register periodic task (every 15 minutes - minimum allowed by OS)
  await Workmanager().registerPeriodicTask(
    "1",
    backgroundTaskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.not_required,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final storageService = await StorageService.init();

  final notificationService = NotificationService.instance;
  final notificationInitialized = await notificationService.initialize();

  if (notificationInitialized) {
    await notificationService.requestPermissions();
    Logger.info('Notification service initialized', 'main');
  } else {
    Logger.error('failed to initialize notification service', null, null, 'main');
  }

  final apiService = ApiService();
  final speechService = SpeechService();
  await speechService.initialize();
  final calendarService = CalendarService();

  final reminderRepository = ReminderRepository(storageService, apiService);
  final settingsRepository = SettingsRepository(storageService);

  final geofenceService = GeofenceService();

  // NoteWise Logic Port: Initialize Security Ensemble
  final fingerprint = await FingerprintService.getFingerprint();
  Logger.debug('Hardware Anchor Verified: $fingerprint', 'SECURITY');
  
  // Initialize decryption for existing vault data
  await EncryptionService.initialize('vault_admin'); 

  final queueService = QueueService(reminderRepository, notificationService);

  final reminderViewModel = ReminderViewModel(
    reminderRepository,
    notificationService,
    geofenceService,
    speechService,
    calendarService,
    queueService,
  );
  await reminderViewModel.initialize();

  final themeViewModel = ThemeViewModel(settingsRepository);
  await themeViewModel.load();

  notificationService.registerResponseHandler(reminderViewModel.handleNotificationResponse);

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('hi', 'IN'),
        Locale('ur', 'PK'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      useOnlyLangCode: true,
      child: AutonomousReminderApp(
        reminderViewModel: reminderViewModel,
        themeViewModel: themeViewModel,
      ),
    ),
  );
}
