import 'package:flutter_test/flutter_test.dart';
import 'package:smart_reminder/core/services/nlp_service.dart';

void main() {
  test('Edge-AI Performance Benchmarking', () {
    print('--- Edge-AI Performance Benchmarking ---');
    
    final cases = [
      'Meeting with CEO tomorrow at 9 AM',
      'Call mom in 2 hours #personal',
      'Buy medicine Friday high priority',
      'Laundry every Saturday at 10:00 #home',
    ];

    final stopwatch = Stopwatch()..start();
    
    for (final text in cases) {
      final start = DateTime.now().microsecondsSinceEpoch;
      final result = NLPService.parse(text);
      final end = DateTime.now().microsecondsSinceEpoch;
      
      final latency = (end - start) / 1000;
      print('Input: "$text"');
      print('  -> Intent: ${result.category.name}');
      print('  -> Latency: ${latency.toStringAsFixed(3)}ms');
      print('  -> Confidence: ${result.confidence}');
      print('');
    }

    stopwatch.stop();
    final totalTime = stopwatch.elapsedMilliseconds;
    final avgLatency = totalTime / cases.length;
    
    print('Total Benchmark Time: ${totalTime}ms');
    print('Average Latency: ${avgLatency}ms');
    print('--- End of Benchmark ---');

    expect(avgLatency, lessThan(200.0), reason: 'Average latency must be below 200ms threshold.');
  });
}
