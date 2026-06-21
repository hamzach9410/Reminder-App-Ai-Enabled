import '../../data/models/reminder_model.dart';
import '../../data/repositories/reminder_repository.dart';
import 'nlp_service.dart';
import '../utils/logger.dart';
import '../constants/enums.dart';

/// Central orchestrator for the 'Nuclear-Grade' Intelligence Layer.
/// Manages recursive task splitting, collision detection, and fatigue guarding.
class TaskOrchestrator {
  final ReminderRepository _repository;

  TaskOrchestrator(this._repository);

  /// Orchestrate the processing of raw user input into one or more atomic reminders.
  /// [rawInput]: The unparsed string from the user.
  /// Returns a list of [OrchestratedTask] which contInferencen the reminder and conflict data.
  Future<List<OrchestratedTask>> processIntent(String rawInput) async {
    // 1. Edge-Inference Parsing (Recursive split + Professional Mapping)
    final parsedList = NLPService.parse(rawInput);
    final outcomes = <OrchestratedTask>[];

    for (final parsed in parsedList) {
      // 2. Collision Detection (+/- 5 min toggle)
      final collisions = await _repository.findCollidingReminders(parsed.scheduledTime);
      
      // 3. Construct High-Integrity Model
      ReminderModel reminder = ReminderModel.create(
        title: parsed.title,
        dateTime: parsed.scheduledTime,
        priority: parsed.priority,
        recurrence: parsed.recurrence,
        category: parsed.category,
        originalIntent: rawInput,
      );

      outcomes.add(OrchestratedTask(
        reminder: reminder,
        hasCollision: collisions.isNotEmpty,
        collisions: collisions,
      ));

      // 4. Atomic Audit Logging
      await _repository.logAuditAction('INTENT_PROCESSED', {
        'id': reminder.id,
        'title': reminder.title,
        'intent': rawInput,
        'conflicts': collisions.length,
        'scheduled_at': parsed.scheduledTime.toIso8601String(),
      });
    }

    Logger.info('Task Orchestration Complete: ${outcomes.length} atomic outcomes.', 'TASK_ORCH');
    return outcomes;
  }

  /// Evaluate task density to predict cognitive fatigue (Threshold: >3 tasks/hour)
  Future<bool> predictFatigue() async {
    final now = DateTime.now();
    final window = now.add(const Duration(hours: 1));
    
    final all = await _repository.getAllReminders();
    final denseCount = all.where((r) => 
      r.status != ReminderStatus.completed &&
      r.dateTime.isAfter(now) && 
      r.dateTime.isBefore(window)
    ).length;

    if (denseCount >= 3) {
       Logger.warning('High Task Density Detected: Fatigue threshold reached ($denseCount/hr)', 'FATIGUE_GUARD');
       return true;
    }
    return false;
  }
}

/// Metadata-rich result of a task orchestration cycle.
class OrchestratedTask {
  final ReminderModel reminder;
  final bool hasCollision;
  final List<ReminderModel> collisions;

  OrchestratedTask({
    required this.reminder,
    required this.hasCollision,
    required this.collisions,
  });
}
