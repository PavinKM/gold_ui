import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gold_ui/config/app_config.dart';
import 'package:http/http.dart' as http;

abstract class AdminApi {
  Future<bool> getHealth();
  Future<Map<String, dynamic>> getDashboardSummary();
  Future<Map<String, dynamic>> exchangeToken(String requestToken);
  Future<Map<String, dynamic>> getTokenStatus();
  Future<Map<String, dynamic>> getEngineStatus();
  Future<Map<String, dynamic>> getEngineHealth();
  Future<Map<String, dynamic>> startEngine();
  Future<Map<String, dynamic>> stopEngine();
  Future<Map<String, dynamic>> restartEngine();
  Future<Map<String, dynamic>> getPositions();
  Future<Map<String, dynamic>> getEngineState({String symbol = 'GOLD'});
  Future<List<String>> getLogs({int lines = 200});
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
}

class ApiService implements AdminApi {
  ApiService() {
    AppConfig.validateAdminConfig();
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String get _baseUrl => AppConfig.adminBaseUrl;
  String get _adminToken => AppConfig.adminToken;

  Future<Map<String, String>> _getHeaders() async {
    return {'Content-Type': 'application/json', 'X-Admin-Token': _adminToken};
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = json.decode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return <String, dynamic>{'data': decoded};
  }

  Exception _httpException(String action, http.Response response) {
    final body = response.body.isEmpty ? 'no response body' : response.body;
    final snippet = body.length > 240 ? '${body.substring(0, 240)}...' : body;
    return Exception('$action failed: ${response.statusCode} $snippet');
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    bool auth = true,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$_baseUrl$path');
    final mergedHeaders = <String, String>{
      if (auth) ...await _getHeaders(),
      ...?headers,
    };

    final response = await http.get(url, headers: mergedHeaders);
    if (response.statusCode != 200) {
      throw _httpException('GET $path', response);
    }
    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> _postJson(String path, {Object? body}) async {
    final url = Uri.parse('$_baseUrl$path');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: body == null ? null : json.encode(body),
    );

    if (response.statusCode != 200) {
      throw _httpException('POST $path', response);
    }
    return _decodeObject(response);
  }

  @override
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'zerodha_access_token', value: token);
  }

  @override
  Future<String?> getToken() async {
    return _storage.read(key: 'zerodha_access_token');
  }

  @override
  Future<void> clearToken() async {
    await _storage.delete(key: 'zerodha_access_token');
  }

  @override
  Future<bool> getHealth() async {
    final response = await _getJson('/healthz', auth: false);
    return response['ok'] == true;
  }

  @override
  Future<Map<String, dynamic>> getDashboardSummary() {
    return _getJson('/dashboard/summary');
  }

  @override
  Future<Map<String, dynamic>> exchangeToken(String requestToken) {
    return _postJson(
      '/kite/exchange-token',
      body: {'request_token': requestToken},
    );
  }

  @override
  Future<Map<String, dynamic>> getTokenStatus() {
    return _getJson('/kite/token-status');
  }

  @override
  Future<Map<String, dynamic>> getEngineStatus() {
    return _getJson('/engine/status');
  }

  @override
  Future<Map<String, dynamic>> getEngineHealth() {
    return _getJson('/engine/health');
  }

  @override
  Future<Map<String, dynamic>> startEngine() {
    return _postJson('/engine/start');
  }

  @override
  Future<Map<String, dynamic>> stopEngine() {
    return _postJson('/engine/stop');
  }

  @override
  Future<Map<String, dynamic>> restartEngine() {
    return _postJson('/engine/restart');
  }

  @override
  Future<Map<String, dynamic>> getPositions() async {
    final response = await _getJson(
      '/engine/open-position',
      headers: {'accept': 'application/json'},
    );
    debugPrint('Positions payload received: ${response.keys.join(', ')}');
    return response;
  }

  @override
  Future<Map<String, dynamic>> getEngineState({String symbol = 'GOLD'}) {
    final encodedSymbol = Uri.encodeQueryComponent(symbol);
    return _getJson('/engine/setup-state?symbol=$encodedSymbol');
  }

  @override
  Future<List<String>> getLogs({int lines = 200}) async {
    final response = await _getJson('/logs/recent?lines=$lines');
    final decodedLogs = response['logs'] ?? response['lines'];
    if (decodedLogs is List) {
      return decodedLogs.map((entry) => entry.toString()).toList();
    }
    return <String>[json.encode(response)];
  }
}
