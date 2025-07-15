// File: lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/completion_type.dart';
import '../services/api_service.dart';
import 'event_form_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _apiService = ApiService();
  List<Event> _events = [];
  CompletionType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = _selectedFilter == null
        ? await _apiService.getCompletedEvents()
        : await _apiService.getEventsByType(_selectedFilter!);
    setState(() => _events = events);
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

  void _openEditForm(Event event) async {
    final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventFormScreen(event: event, mode: 'reschedule'),
                            ),
                          );
    if (updated == true) _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              final type = await showDialog<CompletionType?>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Filter by Status'),
                  children: [
                    SimpleDialogOption(
                      child: const Text('All'),
                      onPressed: () => Navigator.pop(context, null),
                    ),
                    ...CompletionType.values.map((type) => SimpleDialogOption(
                          child: Text(type.name),
                          onPressed: () => Navigator.pop(context, type),
                        ))
                  ],
                ),
              );
              setState(() => _selectedFilter = type);
              _loadEvents();
            },
          ),
        ],
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
                    if (event.note != null && event.note!.isNotEmpty)
                      Text('Note: ${event.note}'),
                    if (event.completionType != null)
                      Text('Status: ${event.completionType}')
                  ],
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note),
                      onPressed: () => _markTypeAndNote(event),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_calendar),
                      onPressed: () => _openEditForm(event),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
