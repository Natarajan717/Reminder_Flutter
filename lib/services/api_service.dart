// File: lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';
import '../models/completion_type.dart';

class ApiService {
  static const String baseUrl = 'https://reminder-backend-rm7x.onrender.com/api/events';

  Future<List<Event>> getUpcomingEvents() async {
    final response = await http.get(Uri.parse('$baseUrl/upcoming'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Event.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load upcoming events');
    }
  }

  Future<List<Event>> getCompletedEvents() async {
    final response = await http.get(Uri.parse('$baseUrl/history'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Event.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load completed events');
    }
  }

  Future<List<Event>> getEventsByType(CompletionType type) async {
    final response = await http.get(Uri.parse('$baseUrl/history?type=${type.name}'));
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
      headers: {'Content-Type': 'application/json'},
      body: json.encode(event.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create event');
    }
  }

  Future<void> updateEvent(int id, Event event) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(event.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update event');
    }
  }

  Future<void> deleteEvent(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete event');
    }
  }

  Future<void> markEventCompleted(int id, CompletionType type, String note) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$id/complete'),
      headers: {'Content-Type': 'application/json'},
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
