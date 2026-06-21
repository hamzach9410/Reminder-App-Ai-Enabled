import '../utils/logger.dart';
import '../constants/enums.dart';
import '../utils/text_parser.dart';

/// The result of an "Autonomous" NLP parsing operation, including confidence and category.
class AutonomousParsedReminder {
  final String title;
  final DateTime scheduledTime;
  final ReminderCategory category;
  final double confidence;
  final bool requiresConfirmation;
  final RecurrenceType recurrence;
  final Priority priority;

  AutonomousParsedReminder({
    required this.title,
    required this.scheduledTime,
    required this.category,
    required this.confidence,
    required this.requiresConfirmation,
    required this.priority,
    this.recurrence = RecurrenceType.none,
  });
}

/// Natural Language Processing service - transformed into a recursive LinguisticInferenceEngine.
/// Strictly handles Edge-Inference processing with zero external dependencies.
class NLPService {
  // Professional Transformation Dictionary
  static const Map<String, String> _professionalMapping = {
    'namaz': 'Spiritual Observance: Namaz',
    'salah': 'Spiritual Observance: Salah',
    'food': 'Nutritional Break',
    'lunch': 'Nutritional Break: Lunch',
    'dinner': 'Nutritional Break: Dinner',
    'exercise': 'Physical Optimization: Exercise',
    'gym': 'Physical Optimization: Gym',
    'medicine': 'Biological maintenance: Medicine',
    'pills': 'Biological maintenance: Medication',
    'water': 'Hydration Reset',
    'sleep': 'Neural Recharge: Rest',
    'meeting': 'Collaborative Sync',
    'call': 'Communication Protocol',
    'work': 'Operational Focus',
    'payment': 'Financial Transaction',
    'bill': 'Financial Liability',
  };

  static const Map<ReminderCategory, List<String>> _categoryKeywords = {
    ReminderCategory.work: [
      'meeting', 'call', 'standup', 'email', 'deadline', 'report', 'project', 'work', 'office',
      'presentation', 'client', 'sync', 'task', 'job'
    ],
    ReminderCategory.health: [
      'medicine', 'doctor', 'appointment', 'vaccine', 'pills', 'yoga', 'exercise', 'gym', 'water',
      'hospital', 'dentist', 'nutrition', 'workout', 'vitamin'
    ],
    ReminderCategory.finance: [
      'payment', 'bill', 'tax', 'invoice', 'loan', 'budget', 'rent', 'salary', 'bank',
      'credit', 'card', 'insurance', 'subscription', 'expense'
    ],
    ReminderCategory.personal: [
      'mom', 'dad', 'family', 'grocery', 'laundry', 'birthday', 'dinner', 'lunch', 'party',
      'friends', 'shopping', 'gift', 'clean', 'home'
    ],
  };

  /// Parses input text into a high-confidence structured reminder object.
  /// Parses input text into one or more structured reminder objects.
  /// Supports recursive multi-intent extraction (e.g., "namaz after 3 min, dinner after 1 hour").
  static List<AutonomousParsedReminder> parse(String text) {
    final stopwatch = Stopwatch()..start();
    final anchor = DateTime.now();
    
    // 1. Split Multi-Intent segments (Recursive Extraction)
    final segments = _splitIntents(text);
    final results = <AutonomousParsedReminder>[];

    for (final segment in segments) {
      if (segment.trim().length <= 3) continue;
      
      // 2. Base extraction per segment with Temporal Anchoring
      final baseResult = TextParser.parseReminderText(segment, baseTime: anchor);
      final rawTitleLower = baseResult.title.toLowerCase();

      // 3. Professional Title Transformation
      String finalTitle = baseResult.title;
      for (final entry in _professionalMapping.entries) {
        if (rawTitleLower.contains(entry.key)) {
          finalTitle = entry.value;
          break;
        }
      }

      // 4. Determine Category (Intent Detection)
      ReminderCategory category = ReminderCategory.personal;
      int highestMatches = 0;
      for (final entry in _categoryKeywords.entries) {
        final matches = entry.value.where((kw) => segment.toLowerCase().contains(kw)).length;
        if (matches > highestMatches) {
          category = entry.key;
          highestMatches = matches;
        }
      }

      // 5. Confidence scoring
      double confidence = 0.5;
      if (baseResult.dateTime != null) confidence += 0.3;
      if (baseResult.title.length > 5) confidence += 0.1;
      if (highestMatches > 0) confidence += 0.1;
      confidence = confidence.clamp(0.0, 1.0);

      // 6. Heuristic priority
      Priority priority = baseResult.priority;
      if (category == ReminderCategory.work || category == ReminderCategory.finance) {
        priority = Priority.high;
      }

      results.add(AutonomousParsedReminder(
        title: finalTitle,
        scheduledTime: baseResult.dateTime ?? anchor.add(const Duration(days: 1)),
        category: category,
        confidence: confidence,
        requiresConfirmation: confidence < 0.7,
        recurrence: baseResult.recurrence,
        priority: priority,
      ));
    }

    stopwatch.stop();
    Logger.debug(
      'Edge-Inference Ensemble: [${results.length}] intents extracted | Latency: ${stopwatch.elapsedMicroseconds / 1000}ms',
      'EDGE_INFERENCE'
    );

    return results;
  }

  /// Split raw string into atomic intents using common delimiters.
  static List<String> _splitIntents(String input) {
    // Delimiters for task partitioning
    final delimiters = RegExp(r'\s+and\s+|\s+then\s+|[,;.]');
    return input.split(delimiters).where((s) => s.trim().length > 3).toList();
  }

  /// Check if a time is still valid for scheduling.
  static bool isFuture(DateTime time) => time.isAfter(DateTime.now());
}
