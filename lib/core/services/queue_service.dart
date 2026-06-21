import 'package:flutter/foundation.dart';
import '../../data/models/reminder_model.dart';
import '../../data/repositories/reminder_repository.dart';
import 'cron_engine.dart';
import 'notification_service.dart';
import '../../core/constants/enums.dart';
import '../../core/utils/logger.dart';

/// QueueService manages the execution of reminder triggers.
/// Ported from NoteWise logic.
class QueueService {
  final ReminderRepository _repository;
  final NotificationService _notificationService;

  static bool _isProcessing = false;

  QueueService(this._repository, this._notificationService);

  /// main worker loop to process due jobs.
  /// This is called by Workmanager or App background tasks.
  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final now = DateTime.now();
      // Implementation detail: we fetch reminders that are in 'pending' or 'snoozed' status
      // and whose scheduled time is in the past.
      final reminders = await _repository.getAllReminders();
      final dueReminders = reminders.where((r) {
        if (r.status == ReminderStatus.completed) return false;
        
        final scheduledTime = r.status == ReminderStatus.snoozed && r.snoozedUntil != null
            ? r.snoozedUntil!
            : r.dateTime;
            
        return scheduledTime.isBefore(now) || scheduledTime.isAtSameMomentAs(now);
      }).toList();

      Logger.info('[QueueService] Found ${dueReminders.length} due reminders', 'QueueService');

      for (final reminder in dueReminders) {
        await _executeJob(reminder);
      }
    } catch (error, stackTrace) {
      Logger.error('[QueueService] Queue processing failed', error, stackTrace, 'QueueService');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _executeJob(ReminderModel reminder) async {
    Logger.info('[QueueService] Executing job for: ${reminder.title}', 'QueueService');

    try {
      // 1. Mark as notified/shown (internal state logic)
      // NoteWise marks as 'sent', our app uses 'pending' but we fire notification
      
      // 2. Trigger notification
      await _notificationService.showNotification(
        title: reminder.title,
        body: reminder.description ?? 'Reminder',
        payload: reminder.id,
      );

      // 3. Handle recurrence (Auto-reschedule logic from NoteWise)
      if (reminder.recurrence != RecurrenceType.none) {
        await _rescheduleRecurringReminder(reminder);
      } else {
        // If it's a one-time reminder that just executed, 
        // NoteWise sometimes leaves it, but we might want to mark it as 'completed' 
        // or just let the user mark it. NoteWise's QueueService marks as 'sent'.
        // To match parity, we'll keep it pending until user Interacts. 
      }
    } catch (error, stackTrace) {
      Logger.error('[QueueService] failed to execute job ${reminder.id}', error, stackTrace, 'QueueService');
    }
  }

  Future<void> _rescheduleRecurringReminder(ReminderModel reminder) async {
    // Generate CRON rule based on the recurrence type and original time
    final typeStr = reminder.recurrence.name; 
    final rule = CronEngine.generateRule(
      type: typeStr,
      time: reminder.dateTime,
    );
    
    final nextRunAt = CronEngine.getNextRunAt(rule);
    
    Logger.info('[QueueService] Rescheduling recurring reminder (Cloning for parity): ${reminder.id} for $nextRunAt', 'QueueService');
    
    // NoteWise Parity: We create a NEW reminder instance for the next occurrence
    // This allows the current one to stay in history as 'completed' or 'sent'.
    final nextReminder = ReminderModel.create(
      title: reminder.title,
      description: reminder.description,
      dateTime: nextRunAt,
      priority: reminder.priority,
      recurrence: reminder.recurrence,
      category: reminder.category,
    );
    
    // Update original reminder to 'completed' or 'sent' so it doesn't trigger agInferencen
    final completedOriginal = reminder.copyWith(status: ReminderStatus.completed);
    await _repository.saveReminder(completedOriginal);
    
    // Save the next occurrence
    await _repository.saveReminder(nextReminder);
  }
}
