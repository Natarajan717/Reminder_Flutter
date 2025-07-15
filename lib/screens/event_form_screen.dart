import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/api_service.dart';

class EventFormScreen extends StatefulWidget {
  final Event? event;
  final String mode; // "new", "edit", or "reschedule"
  const EventFormScreen({super.key, this.event, required this.mode});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _emailController;
  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  int _remindBefore = 10;
  int _repeatInterval = 5;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleController = TextEditingController(text: e?.title);
    _descriptionController = TextEditingController(text: e?.note);
    _emailController = TextEditingController(text: e?.email ?? '');
    if (e != null) {
      _eventDate = e.eventTime;
      _eventTime = TimeOfDay.fromDateTime(e.eventTime);
      _remindBefore = e.remindBeforeMinutes;
      _repeatInterval = e.repeatAfterMinutes;
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && _eventDate != null && _eventTime != null) {
      final fullDate = DateTime(
        _eventDate!.year,
        _eventDate!.month,
        _eventDate!.day,
        _eventTime!.hour,
        _eventTime!.minute,
      );

    //  Convert local time to UTC
    final utcDateTime = fullDate.toUtc();

      final newEvent = Event(
        id: widget.event?.id,
        title: _titleController.text,
        note: _descriptionController.text,
        email: _emailController.text,
        eventTime: utcDateTime,
        remindBeforeMinutes: _remindBefore,
        repeatAfterMinutes: _repeatInterval,
      );

      if (widget.event == null) {
        await _apiService.createEvent(newEvent);
      } else {
        await _apiService.updateEvent(newEvent.id!, newEvent);
      }

      if (context.mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == 'edit'
              ? 'Edit Event'
              : widget.mode == 'reschedule'
                  ? 'Reschedule Event'
                  : 'New Event',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (val) => val == null || val.isEmpty ? 'Enter title' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'note'),
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(_eventDate != null ? _eventDate!.toLocal().toString().split(' ')[0] : 'Select date'),
                onTap: () async {
                  final now = DateTime.now();
                  final initialDate = _eventDate != null && _eventDate!.isAfter(now) ? _eventDate! : now;
                  final firstDate = widget.mode == 'reschedule' && _eventDate != null
                      ? _eventDate!.isBefore(now)
                      ? _eventDate!
                      : now
                      : now;

                  final date = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: firstDate,
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _eventDate = date);
                },
              ),
              ListTile(
                title: const Text('Time'),
                subtitle: Text(_eventTime != null ? _eventTime!.format(context) : 'Select time'),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _eventTime ?? TimeOfDay.now(),
                  );
                  if (time != null) setState(() => _eventTime = time);
                },
              ),
              DropdownButtonFormField<int>(
                value: _remindBefore,
                items: const [5, 10, 15, 30, 60].map((val) => DropdownMenuItem(value: val, child: Text('$val minutes before'))).toList(),
                onChanged: (val) => setState(() => _remindBefore = val!),
                decoration: const InputDecoration(labelText: 'Remind Before'),
              ),
              DropdownButtonFormField<int>(
                value: _repeatInterval,
                items: const [1, 5, 10, 15].map((val) => DropdownMenuItem(value: val, child: Text('Every $val minutes'))).toList(),
                onChanged: (val) => setState(() => _repeatInterval = val!),
                decoration: const InputDecoration(labelText: 'Repeat Interval'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submit, child: const Text('Save Event')),
            ],
          ),
        ),
      ),
    );
  }
}