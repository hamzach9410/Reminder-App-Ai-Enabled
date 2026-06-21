import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../data/models/reminder_model.dart';
import '../utils/logger.dart';

/// Calendar Synchronization Service ported from NoteWise.
/// Ensures reminders are reflected in the device's native calendar (Google/iCloud).
class CalendarService {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  static const String _calendarName = 'Autonomous Vaults';

  /// Synchronize a reminder to the device calendar.
  Future<bool> syncReminder(ReminderModel reminder) async {
    try {
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) return false;

      final calendarId = await _getOrCreateCalendar();
      if (calendarId == null) return false;

      // Prepare calendar event
      final event = Event(
        calendarId,
        eventId: reminder.calendarEventId, // Try to update existing if ID exists
        title: '🔔 ${reminder.title}',
        description: reminder.description ?? 'Autonomous Vault',
        start: tz.TZDateTime.from(reminder.dateTime, tz.local),
        end: tz.TZDateTime.from(
          reminder.dateTime.add(const Duration(minutes: 30)), 
          tz.local
        ),
      );

      final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      
      if (result != null && result.isSuccess && result.data != null) {
        Logger.info('Synced reminder ${reminder.id} to calendar event ${result.data}', 'CalendarService');
        // Note: The caller should save the returned event ID to the reminder model
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('Calendar sync failed', e, null, 'CalendarService');
      return false;
    }
  }

  /// Remove a reminder from the device calendar.
  Future<bool> deleteEvent(String? eventId) async {
    if (eventId == null || eventId.isEmpty) return true;
    
    try {
      final calendarId = await _getOrCreateCalendar();
      if (calendarId == null) return false;

      final result = await _deviceCalendarPlugin.deleteEvent(calendarId, eventId);
      return result.isSuccess;
    } catch (e) {
      Logger.error('failed to delete calendar event', e, null, 'CalendarService');
      return false;
    }
  }

  Future<bool> _requestPermissions() async {
    final permissions = await _deviceCalendarPlugin.requestPermissions();
    return permissions.isSuccess && permissions.data == true;
  }

  Future<String?> _getOrCreateCalendar() async {
    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    if (!calendarsResult.isSuccess || calendarsResult.data == null) return null;

    final calendars = calendarsResult.data!;
    
    // Look for existing app calendar
    final existing = calendars.firstWhere(
      (c) => c.name == _calendarName,
      orElse: () => Calendar(id: ''),
    );

    if (existing.id != null && existing.id!.isNotEmpty) {
      return existing.id;
    }

    // Create a new one (Note: Android usually requires a manual calendar setup in some versions, 
    // but on iOS/Modern Android we can request one)
    // For simplicity, we'll try to use the default calendar if we can't create one.
    final defaultCalendar = calendars.firstWhere(
      (c) => c.isDefault == true,
      orElse: () => calendars.isNotEmpty ? calendars.first : Calendar(id: ''),
    );

    return defaultCalendar.id;
  }
}
