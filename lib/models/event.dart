class Event {
  int? id;
  String title;
  String email;
  DateTime eventTime;
  int remindBeforeMinutes;
  int repeatAfterMinutes;
  String? note;
  String? completionType;

  Event({
    this.id,
    required this.title,
    required this.email,
    required this.eventTime,
    required this.remindBeforeMinutes,
    required this.repeatAfterMinutes,
    this.note,
    this.completionType,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      email: json['email'],
      eventTime: DateTime.parse(json['eventTime']),
      remindBeforeMinutes: json['remindBeforeMinutes'],
      repeatAfterMinutes: json['repeatAfterMinutes'],
      note: json['note'],
      completionType: json['completionType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'email': email,
      'eventTime': eventTime.toIso8601String(),
      'remindBeforeMinutes': remindBeforeMinutes,
      'repeatAfterMinutes': repeatAfterMinutes,
      'note': note,
      'completionType': completionType,
    };
  }
}
