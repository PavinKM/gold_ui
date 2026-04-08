import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://178.156.146.28:8088/api/v1';
  static const String adminToken = 'Test';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
      'X-Admin-Token': adminToken,
    };
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'zerodha_access_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'zerodha_access_token');
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'zerodha_access_token');
  }

  // Future<bool> getHealth() async {
  //   final url = Uri.parse('$baseUrl/healthz');
  //   try {
  //     final response = await http.get(url);
  //     return response.statusCode == 200;
  //   } catch (_) {
  //     return false;
  //   }
  // }

  Future<bool> getHealth() async {
    final url = Uri.parse('$baseUrl/healthz');

    try {
      final response = await http.get(url);

      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ok'] == true;
      }

      return false;
    } catch (e) {
      print("ERROR: $e");
      return false;
    }
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

  Future<Map<String, dynamic>> getEngineHealth() async {
    final url = Uri.parse('$baseUrl/engine/health');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load engine health: ${response.statusCode}');
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

  // Future<List<dynamic>> getPositions() async {
  //   final url = Uri.parse('$baseUrl/api/v1/engine/open-position');

  //   try {
  //     final response = await http.get(url);

  //     print("POSITIONS STATUS: ${response.statusCode}");
  //     print("POSITIONS BODY: ${response.body}");

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);

  //       // 🔥 handle multiple formats safely
  //       if (data is List) {
  //         return data;
  //       } else if (data['data'] != null) {
  //         return data['data'];
  //       } else if (data['positions'] != null) {
  //         return data['positions'];
  //       } else {
  //         return [];
  //       }
  //     } else {
  //       throw Exception("Failed to fetch positions");
  //     }
  //   } catch (e) {
  //     print("ERROR: $e");
  //     throw Exception("Error fetching positions");
  //   }
  // }
  // Future<List<dynamic>> getPositions() async {
  //   final url = Uri.parse('$baseUrl/api/v1/engine/open-position');

  //   final response = await http.get(
  //     url,
  //     headers: {
  //       "Content-Type": "application/json",
  //       "X-Admin-Token": adminToken, // 🔥 ADD THIS
  //     },
  //   );

  //   print("POSITIONS STATUS: ${response.statusCode}");
  //   print("POSITIONS BODY: ${response.body}");

  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body);
  //   } else {
  //     throw Exception("Failed to fetch positions");
  //   }
  // }

  Future<Map<String, dynamic>> getPositions() async {
    // final url = Uri.parse('$baseUrl/api/v1/engine/open-position');
    final url = Uri.parse('$baseUrl/engine/open-position');

    final response = await http.get(
      url,
      headers: {
        "accept": "application/json", // ✅ IMPORTANT
        "X-Admin-Token": "Test",      // ✅ EXACT SAME as curl
      },
    );

    print("URL: $url");
    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch positions");
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
