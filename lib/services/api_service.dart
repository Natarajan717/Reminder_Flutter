// File: lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import '../models/completion_type.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8082/api/events';
  static const String authBaseUrl = 'http://10.0.2.2:8082';

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

  Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$authBaseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": email, "password": password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['token'];
    }
    return null;
  }

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token");
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
