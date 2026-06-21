import 'package:flutter_test/flutter_test.dart';
import 'package:smart_reminder/data/models/reminder_model.dart';
import 'package:smart_reminder/data/repositories/reminder_repository.dart';
import 'package:smart_reminder/core/services/api_service.dart';
import 'package:smart_reminder/core/services/storage_service.dart';
import 'package:hive/hive.dart';

/// Manual Mock for Hive Box
class MockBox extends Fake implements Box<Map> {
  final Map<dynamic, Map> data = {};
  final List<Map> putCalls = [];
  List<Map>? valuesOverride;

  @override
  Iterable<Map> get values => valuesOverride ?? data.values.cast<Map>();

  @override
  Future<void> put(key, Map value) async {
    data[key] = value;
    putCalls.add(value);
  }

  @override
  Map? get(key, {Map? defaultValue}) => data[key] ?? defaultValue;

  @override
  Future<int> clear() async {
    data.clear();
    return 0;
  }
}

/// Manual Mock for StorageService
class MockStorageService extends Fake implements StorageService {
  late Box<Map> box;
  @override
  Box<Map> get remindersBox => box;
}

/// Manual Mock for ApiService
class MockApiService extends Fake implements ApiService {
  List<List<Map<String, dynamic>>> syncCalls = [];
  bool shouldSucceed = true;

  @override
  Future<bool> syncReminders(List<Map<String, dynamic>> reminders) async {
    syncCalls.add(reminders);
    return shouldSucceed;
  }
}

void main() {
  group('Delta-Sync Integrity Tests', () {
    late ReminderRepository repository;
    late MockStorageService mockStorage;
    late MockApiService mockApi;
    late MockBox mockBox;

    setUp(() {
      mockBox = MockBox();
      mockStorage = MockStorageService()..box = mockBox;
      mockApi = MockApiService();
      repository = ReminderRepository(mockStorage, mockApi);
    });

    test('Delta-Sync: Should only send non-synced (dirty) reminders', () async {
      final now = DateTime.now();
      final reminder1 = ReminderModel.create(title: 'Synced', dateTime: now, isSynced: true, updatedAt: now);
      final reminder2 = ReminderModel.create(title: 'Dirty', dateTime: now, isSynced: false, updatedAt: now);

      mockBox.valuesOverride = [reminder1.toJson(), reminder2.toJson()];

      await repository.syncWithCloud();

      expect(mockApi.syncCalls.length, 1);
      expect(mockApi.syncCalls.first.length, 1);
      expect(mockApi.syncCalls.first[0]['title'], 'Dirty');
    });

    test('Sync Recovery: Should mark as synced locally after success', () async {
      final now = DateTime.now();
      final reminder = ReminderModel.create(title: 'Test', dateTime: now, isSynced: false, updatedAt: now);
      mockBox.valuesOverride = [reminder.toJson()];

      await repository.syncWithCloud();

      // Check if the last put call was marking it as synced
      final capturedJson = mockBox.putCalls.last;
      expect(capturedJson['isSynced'], true);
    });
  });
}
