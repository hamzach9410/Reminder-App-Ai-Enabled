import '../../core/constants/enums.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/encryption_service.dart';
import '../../core/utils/logger.dart';
import '../../core/services/semantic_search_service.dart';
import '../models/reminder_model.dart';

/// Repository for managing reminder data
/// Handles all CRUD operations for reminders
class ReminderRepository {
  final StorageService _storage;
  final ApiService _api;

  ReminderRepository(this._storage, this._api);

  /// Find any reminders that conflict within a +/- 5 minute window
  Future<List<ReminderModel>> findCollidingReminders(DateTime targetTime) async {
    final all = await getAllReminders();
    const window = Duration(minutes: 5);
    
    return all.where((r) {
      if (r.status == ReminderStatus.completed) return false;
      final diff = r.dateTime.difference(targetTime).abs();
      return diff <= window;
    }).toList();
  }

  /// Log a transaction to the atomic audit trail
  Future<void> logAuditAction(String action, Map<String, dynamic> metadata) async {
    try {
      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'action': action,
        'metadata': metadata,
      };
      await _storage.auditBox.add(logEntry);
      Logger.debug('Audit Log: $action', 'AUDIT_VAULT');
    } catch (e) {
       Logger.error('Logging failed', e, null, 'AUDIT_VAULT');
    }
  }

  /// Get all reminders
  Future<List<ReminderModel>> getAllReminders() async {
    try {
      final reminders = _storage.remindersBox.values.map((json) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(json);
        
        // NoteWise parity: Decrypt in-memory
        if (data.containsKey('title')) {
          data['title'] = EncryptionService.decrypt(data['title'] as String);
        }
        if (data.containsKey('description') && data['description'] != null) {
          data['description'] = EncryptionService.decrypt(data['description'] as String);
        }
        
        return ReminderModel.fromJson(data);
      }).toList();

      reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      Logger.debug('Loaded ${reminders.length} reminders (Decrypted for UI)', 'STORAGE_VAULT');
      return reminders;
    } catch (e, stackTrace) {
      Logger.error('failed to get all reminders', e, stackTrace, 'STORAGE_VAULT');
      return [];
    }
  }

  /// Get reminder by ID
  Future<ReminderModel?> getReminderById(String id) async {
    try {
      final json = _storage.remindersBox.get(id);
      if (json == null) return null;
      return ReminderModel.fromJson(Map<String, dynamic>.from(json));
    } catch (e, stackTrace) {
      Logger.error('failed to get reminder by ID: $id', e, stackTrace, 'STORAGE_VAULT');
      return null;
    }
  }

  /// Save reminder (create or update)
  Future<bool> saveReminder(ReminderModel reminder) async {
    try {
      // Ensure local modification metadata is updated
      final updatedReminder = reminder.copyWith(
        isSynced: false,
        updatedAt: DateTime.now(),
        intentMetadata: {
          ...reminder.intentMetadata,
          ...SemanticSearchService.generateTokens(reminder.title),
        },
      );
      
      final jsonData = updatedReminder.toJson();
      
      // NoteWise parity: Encrypt before storage
      jsonData['title'] = EncryptionService.encrypt(updatedReminder.title);
      if (updatedReminder.description != null) {
        jsonData['description'] = EncryptionService.encrypt(updatedReminder.description!);
      }
      
      await _storage.remindersBox.put(updatedReminder.id, jsonData);
      Logger.info('Saved reminder (Vault Encrypted & Dirty-Marked): ${updatedReminder.id}', 'STORAGE_VAULT');
      return true;
    } catch (e, stackTrace) {
      Logger.error('failed to save reminder: ${reminder.id}', e, stackTrace, 'STORAGE_VAULT');
      return false;
    }
  }

  /// Delete reminder
  Future<bool> deleteReminder(String id) async {
    try {
      await _storage.remindersBox.delete(id);
      Logger.info('Deleted reminder: $id', 'STORAGE_VAULT');
      return true;
    } catch (e, stackTrace) {
      Logger.error('failed to delete reminder: $id', e, stackTrace, 'STORAGE_VAULT');
      return false;
    }
  }

  /// Get reminders by status
  Future<List<ReminderModel>> getRemindersByStatus(Set<ReminderStatus> statuses) async {
    try {
      final reminders = await getAllReminders();
      return reminders.where((r) => statuses.contains(r.status)).toList();
    } catch (e, stackTrace) {
      Logger.error('failed to get reminders by status', e, stackTrace, 'ReminderRepository');
      return [];
    }
  }

  /// Clear all reminders
  Future<bool> clearAllReminders() async {
    try {
      await _storage.remindersBox.clear();
      return true;
    } catch (e, stackTrace) {
      Logger.error('failed to clear all reminders', e, stackTrace, 'ReminderRepository');
      return false;
    }
  }

  /// Synchronize local reminders with the cloud backend
  /// NoteWise Parity: Granular Delta-Sync logic
  /// Only pushes modified/new items to the cloud backend.
  Future<bool> syncWithCloud() async {
    try {
      final allReminders = await getAllReminders();
      final dirtyReminders = allReminders.where((r) => !r.isSynced).toList();
      
      if (dirtyReminders.isEmpty) {
        Logger.info('Cloud Sync: No pending changes to push.', 'SYNC_ENGINE');
        return true;
      }

      Logger.info('Pushing ${dirtyReminders.length} dirty reminders to cloud', 'SYNC_ENGINE');
      final jsonData = dirtyReminders.map((r) {
        final data = r.toJson();
        // Privacy Shield: Strip local tokens before cloud persistence
        if (data.containsKey('intentMetadata') && data['intentMetadata'] is Map) {
          final metadata = Map<String, dynamic>.from(data['intentMetadata'] as Map);
          metadata.remove('tokens');
          data['intentMetadata'] = metadata;
        }
        return data;
      }).toList();
      
      final success = await _api.syncReminders(jsonData);
      if (success) {
        // Mark as synced locally
        for (final r in dirtyReminders) {
          final synced = r.copyWith(isSynced: true);
          final rawJson = synced.toJson();
          // Keep encrypted in box
          rawJson['title'] = EncryptionService.encrypt(synced.title);
          if (synced.description != null) {
            rawJson['description'] = EncryptionService.encrypt(synced.description!);
          }
          await _storage.remindersBox.put(synced.id, rawJson);
        }
        Logger.info('Cloud synchronization successful: Delta Pushed', 'SYNC_ENGINE');
        return true;
      } else {
        Logger.error('Cloud synchronization failed', null, null, 'SYNC_ENGINE');
        return false;
      }
    } catch (e, stackTrace) {
      Logger.error('Error during cloud synchronization', e, stackTrace, 'SYNC_ENGINE');
      return false;
    }
  }
}
