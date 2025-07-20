// File: lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import '../models/completion_type.dart';

class ApiService {
  static const String baseUrl = 'https://reminder-backend-rm7x.onrender.com/api/events';
  static const String authBaseUrl = 'https://reminder-backend-rm7x.onrender.com';

  // Future<bool> register(String name, String email, String password) async {
  //   final response = await http.post(
  //     Uri.parse("$authBaseUrl/auth/register"),
  //     headers: {"Content-Type": "application/json"},
  //     body: jsonEncode({"name": name, "email": email, "password": password}),
  //   );
  //   return response.statusCode == 201;
  // }

  Future<bool> register(String name, String email, String password) async {
    final url = Uri.parse("$authBaseUrl/auth/register");
    final body = jsonEncode({"name": name, "email": email, "password": password});
    final headers = {"Content-Type": "application/json"};

    print("🔸 Register API Called");
    print("➡️ URL: $url");
    print("➡️ Body: $body");
    print("➡️ Headers: $headers");

    final response = await http.post(url, headers: headers, body: body);

    print("⬅️ Status Code: ${response.statusCode}");
    print("⬅️ Response Body: ${response.body}");

    return response.statusCode == 201;
  }

  // Future<String?> login(String email, String password) async {
  //   final response = await http.post(
  //     Uri.parse("$authBaseUrl/auth/login"),
  //     headers: {"Content-Type": "application/json"},
  //     body: jsonEncode({"username": email, "password": password}),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body)['token'];
  //   }
  //   return null;
  // }

  // ✅ STEP 1: Update login() to store both tokens
  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$authBaseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("access_token", data['accessToken']);
      await prefs.setString("refresh_token", data['refreshToken']);
      await prefs.setString("email", email);
      return true;
    }
    return false;
  }

  Future<void> sendFcmTokenToBackend(String fcm_token) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString("access_token");

    if (accessToken != null) {
      await http.post(
        Uri.parse("$baseUrl/fcm-token"),
        headers: await _authHeaders(),
        body: jsonEncode({"fcmToken": fcm_token}),
      );
    }
  }

  // Future<Map<String, String>> _authHeaders() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString("jwt_token");
  //   return {
  //     "Content-Type": "application/json",
  //     if (token != null) "Authorization": "Bearer $token"
  //   };
  // }

  // ✅ STEP 2: Add token refresh logic
  Future<String?> refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null) return null;

    final response = await http.post(
      Uri.parse("$authBaseUrl/auth/refresh-token"),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode({"fcmToken": refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newAccessToken = data['accessToken'];
      await prefs.setString("access_token", newAccessToken);
      return newAccessToken;
    }

    return null;
  }

// ✅ STEP 3: Decode JWT and refresh if needed
  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("access_token");

    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
          final expiry = payload['exp'] * 1000;
          final now = DateTime.now().millisecondsSinceEpoch;

          if (expiry < now) {
            token = await refreshAccessToken();
          }
        }
      } catch (_) {
        token = await refreshAccessToken();
      }
    }

    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token"
    };
  }

  Future<List<Event>> getUpcomingEvents() async {
    final response = await http.get(Uri.parse('$baseUrl/upcoming'), headers: await _authHeaders());
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Event.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load upcoming events');
    }
  }

  Future<List<Event>> getCompletedEvents() async {
    final response = await http.get(Uri.parse('$baseUrl/history'), headers: await _authHeaders());
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Event.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load completed events');
    }
  }

  Future<List<Event>> getEventsByType(CompletionType type) async {
    final response = await http.get(Uri.parse('$baseUrl/history?type=${type.name}'), headers: await _authHeaders());
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Event.fromJson(json)).toList();
    } else {
      throw Exception('Failed to filter events');
    }
  }

  Future<void> createEvent(Event event) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _authHeaders(),
      body: json.encode(event.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create event');
    }
  }

  Future<void> updateEvent(int id, Event event) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: await _authHeaders(),
      body: json.encode(event.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update event');
    }
  }

  Future<void> deleteEvent(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'), headers: await _authHeaders());
    if (response.statusCode != 204) {
      throw Exception('Failed to delete event');
    }
  }

  Future<void> markEventCompleted(int id, CompletionType type, String note) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$id/complete'),
      headers: await _authHeaders(),
      body: json.encode({
        'completionType': type.name,
        'note': note,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark event completed');
    }
  }
}
