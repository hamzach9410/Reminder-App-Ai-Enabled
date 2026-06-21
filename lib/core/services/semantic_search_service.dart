import '../../data/models/reminder_model.dart';
import '../utils/logger.dart';

/// Lightweight TF-IDF-inspired local search service.
/// Uses on-device categorization and keyword boosting for "Semantic Search" without external APIs.
class SemanticSearchService {
  // Concept dictionary for boosting relevant results
  static const Map<String, List<String>> _concepts = {
    'health': ['medicine', 'doctor', 'appointment', 'vaccine', 'gym', 'exercise', 'water', 'hospital', 'pain'],
    'work': ['meeting', 'call', 'standup', 'deadline', 'report', 'office', 'project', 'client', 'email'],
    'finance': ['payment', 'bill', 'tax', 'invoice', 'rent', 'bank', 'salary', 'card', 'budget'],
    'personal': ['grocery', 'laundry', 'family', 'home', 'friends', 'shopping', 'dinner', 'party'],
    'spiritual': ['namaz', 'prayer', 'salah', 'mosque', 'meditation'],
  };

  /// Compute high-integrity tokens for a reminder title and store in metadata.
  static Map<String, dynamic> generateTokens(String title) {
    final clean = title.toLowerCase().replaceAll(RegExp(r'[^a-z\s]'), '');
    final tokens = clean.split(' ').where((t) => t.length > 2).toList();
    
    return {
      'tokens': tokens,
      'indexed_at': DateTime.now().toIso8601String(),
    };
  }

  /// Search a list of reminders using conceptual keyword boosting.
  /// Returns a ranked list based on relevance score.
  static List<ReminderModel> search(List<ReminderModel> source, String query) {
    if (query.trim().isEmpty) return source;
    
    final queryTerms = query.toLowerCase().split(' ').where((t) => t.length > 2).toList();
    final Map<String, double> scores = {};

    for (final reminder in source) {
      double score = 0.0;
      final tokens = (reminder.intentMetadata['tokens'] as List?)?.cast<String>() ?? [];
      final fullText = '${reminder.title} ${reminder.description ?? ''}'.toLowerCase();

      for (final term in queryTerms) {
        // 1. Direct match boosting
        if (fullText.contains(term)) score += 10.0;
        if (tokens.contains(term)) score += 5.0;

        // 2. Conceptual boosting (The "Semantic" Part)
        for (final entry in _concepts.entries) {
          if (entry.key == term || entry.value.contains(term)) {
             // The search term belongs to a concept, check if the reminder does too
             for (final keyword in entry.value) {
               if (fullText.contains(keyword)) score += 3.0;
             }
          }
        }
      }

      if (score > 0) {
        scores[reminder.id] = score;
      }
    }

    final results = source.where((r) => scores.containsKey(r.id)).toList();
    results.sort((a, b) => scores[b.id]!.compareTo(scores[a.id]!));
    
    Logger.debug('Semantic Search: Found ${results.length} matches for "$query"', 'SEMANTIC_VAULT');
    return results;
  }
}
