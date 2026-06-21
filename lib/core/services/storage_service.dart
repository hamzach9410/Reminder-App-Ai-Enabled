import 'package:hive_flutter/hive_flutter.dart';
import '../utils/logger.dart';

/// Hive-backed storage service
/// Owns and provides access to app boxes
class StorageService {
  static const String remindersBoxName = 'reminders';
  static const String settingsBoxName = 'settings';
  static const String auditLogBoxName = 'audit_log';

  final Box<Map> remindersBox;
  final Box settingsBox;
  final Box<Map> auditBox;

  StorageService._(this.remindersBox, this.settingsBox, this.auditBox);

  static Future<StorageService> init() async {
    try {
      await Hive.initFlutter();
      final remindersBox = await Hive.openBox<Map>(remindersBoxName);
      final settingsBox = await Hive.openBox(settingsBoxName);
      final auditBox = await Hive.openBox<Map>(auditLogBoxName);
      
      final service = StorageService._(remindersBox, settingsBox, auditBox);
      await service.verifyIntegrity();
      
      Logger.info('Hive storage initialized and integrity verified', 'StorageService');
      return service;
    } catch (e, stackTrace) {
      Logger.error('failed to initialize Hive storage', e, stackTrace, 'StorageService');
      rethrow;
    }
  }

  /// Perform a checksum/integrity check on the reminders box
  Future<void> verifyIntegrity() async {
    try {
      final keys = remindersBox.keys.toList();
      int corruptedCount = 0;
      
      for (final key in keys) {
        final data = remindersBox.get(key);
        if (data == null || data is! Map || !data.containsKey('id')) {
          Logger.warning('Corrupted data detected for key: $key. Purging...', 'STORAGE_VAULT');
          await remindersBox.delete(key);
          corruptedCount++;
        }
      }
      
      if (corruptedCount > 0) {
        Logger.info('Integrity Check Complete: $corruptedCount records purged.', 'STORAGE_VAULT');
      }
    } catch (e) {
      Logger.error('Integrity check failed', e, null, 'STORAGE_VAULT');
    }
  }
}
