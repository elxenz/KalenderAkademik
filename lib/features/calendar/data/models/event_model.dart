import '../../domain/entities/event.dart';

class EventModel extends Event {
  EventModel({
    super.id,
    required super.title,
    super.description,
    required super.date,
    required super.startTime,
    required super.endTime,
    super.colorValue,
    super.isRecurring,
    super.recurrenceRule,
  });

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
      startTime: map['startTime'],
      endTime: map['endTime'],
      colorValue: map['colorValue'],
      isRecurring: map['isRecurring'] == 1,
      recurrenceRule: RecurrenceRule.values.firstWhere(
        (e) => e.name == map['recurrenceRule'],
        orElse: () => RecurrenceRule.none,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String().split('T').first,
      'startTime': startTime,
      'endTime': endTime,
      'colorValue': colorValue,
      'isRecurring': isRecurring ? 1 : 0,
      'recurrenceRule': recurrenceRule.name,
    };
  }
}
