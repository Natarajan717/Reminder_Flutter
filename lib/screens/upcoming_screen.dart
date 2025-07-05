// File: lib/screens/upcoming_screen.dart
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/completion_type.dart';
import '../services/api_service.dart';
import 'event_form_screen.dart';

class UpcomingScreen extends StatefulWidget {
  const UpcomingScreen({super.key});

  @override
  State<UpcomingScreen> createState() => _UpcomingScreenState();
}

class _UpcomingScreenState extends State<UpcomingScreen> {
  final _apiService = ApiService();
  List<Event> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await _apiService.getUpcomingEvents();
    setState(() => _events = events);
  }

  void _openEventForm({Event? event}) async {
    final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventFormScreen(event: event, mode: 'edit'),
                            ),
                          );
    if (updated == true) _loadEvents();
  }
// not used
  Future<void> _markAsCompleted(Event event) async {
    await _apiService.markEventCompleted(
      event.id!,
      CompletionType.completedEarly,
      "Completed early",
    );
    _loadEvents();
  }

 Future<void> _markTypeAndNote(Event event) async {
    final selectedType = await showDialog<CompletionType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Mark Event Type'),
        children: CompletionType.values.map((type) {
          return SimpleDialogOption(
            child: Text(type.name),
            onPressed: () => Navigator.pop(context, type),
          );
        }).toList(),
      ),
    );

    if (selectedType != null) {
      final controller = TextEditingController();
      final note = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Note'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'What happened?'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            )
          ],
        ),
      );

      if (note != null) {
        await _apiService.markEventCompleted(event.id!, selectedType, note);
        _loadEvents();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
              title: const Text('Upcoming Events'),
              backgroundColor: Colors.purple, // or your theme color
       ),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: ListView.builder(
          itemCount: _events.length,
          itemBuilder: (_, i) {
            final event = _events[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(event.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scheduled: ${event.eventTime}'),
                    if (event.note != null)
                      Text('Notes: ${event.note}'),
                  ],
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _openEventForm(event: event),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _markTypeAndNote(event),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEventForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
