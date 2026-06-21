import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import '../constants/app_constants.dart';

/// Service for handling backend API communication
class ApiService {
  final String _baseUrl;
  String? _authToken;

  ApiService({String? baseUrl}) : _baseUrl = baseUrl ?? AppConstants.defaultApiUrl;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  /// Check server health
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (e, stackTrace) {
      Logger.error('failed to check API health', e, stackTrace, 'NETWORK_IO');
      return false;
    }
  }

  /// Generic POST request
  Future<http.Response> post(String path, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return response;
    } catch (e, stackTrace) {
      Logger.error('API POST error: $path', e, stackTrace, 'NETWORK_IO');
      rethrow;
    }
  }

  /// Generic GET request with pagination support
  Future<http.Response> get(String path, {int? page, int? limit}) async {
    try {
      var uri = Uri.parse('$_baseUrl$path');
      if (page != null || limit != null) {
        final queryParams = <String, String>{
          if (page != null) 'page': page.toString(),
          if (limit != null) 'limit': limit.toString(),
        };
        uri = uri.replace(queryParameters: queryParams);
      }
      
      final response = await http.get(
        uri,
        headers: _headers,
      );
      return response;
    } catch (e, stackTrace) {
      Logger.error('API GET error: $path', e, stackTrace, 'NETWORK_IO');
      rethrow;
    }
  }

  /// Sync reminders to cloud
  Future<bool> syncReminders(List<Map<String, dynamic>> reminders) async {
    try {
      final response = await post('/api/reminders/sync', {'reminders': reminders});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
