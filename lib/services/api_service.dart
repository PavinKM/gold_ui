import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _storage.read(key: 'x_admin_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'X-Admin-Token': token,
    };
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'x_admin_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'x_admin_token');
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'x_admin_token');
  }

  Future<Map<String, dynamic>> exchangeToken(String requestToken) async {
    final url = Uri.parse('$baseUrl/kite/exchange-token');
    final headers = await _getHeaders();
    final body = json.encode({'request_token': requestToken});

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to exchange token: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getTokenStatus() async {
    final url = Uri.parse('$baseUrl/kite/token-status');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to status token: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getEngineStatus() async {
    final url = Uri.parse('$baseUrl/engine/status');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load engine status: ${response.statusCode}');
    }
  }

  Future<void> startEngine() async {
    final url = Uri.parse('$baseUrl/engine/start');
    final headers = await _getHeaders();

    final response = await http.post(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to start engine: ${response.statusCode}');
    }
  }

  Future<void> stopEngine() async {
    final url = Uri.parse('$baseUrl/engine/stop');
    final headers = await _getHeaders();

    final response = await http.post(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to stop engine: ${response.statusCode}');
    }
  }

  Future<void> restartEngine() async {
    final url = Uri.parse('$baseUrl/engine/restart');
    final headers = await _getHeaders();

    final response = await http.post(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to restart engine: ${response.statusCode}');
    }
  }

  Future<List<String>> getLogs({int lines = 200}) async {
    final url = Uri.parse('$baseUrl/logs/recent?lines=$lines');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      // Assuming backend returns {"logs": ["line 1", "line 2"]}
      // Adjust this based on actual backend response format
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> && decoded.containsKey('logs')) {
         return List<String>.from(decoded['logs']);
      } else if (decoded is List) {
         return List<String>.from(decoded);
      }
      return [response.body]; 
    } else {
      throw Exception('Failed to get logs');
    }
  }
}
