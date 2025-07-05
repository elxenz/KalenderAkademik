import 'package:flutter/material.dart';
import 'package:kalender/features/calendar/domain/entities/event.dart';
import 'package:kalender/features/calendar/domain/repositories/event_repository.dart';

class EventProvider extends ChangeNotifier {
  final EventRepository eventRepository;

  EventProvider({required this.eventRepository});

  Map<DateTime, List<Event>> _events = {};
  Map<DateTime, List<Event>> get events => _events;

  List<Event> getEventsForDay(DateTime day) {
    // Normalisasi tanggal untuk menghilangkan komponen waktu
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  Future<void> getEvents() async {
    final allEvents = await eventRepository.getAllEvents();
    _events = {}; // Kosongkan map sebelum diisi kembali
    for (var event in allEvents) {
      final day = DateTime(event.date.year, event.date.month, event.date.day);
      if (_events[day] == null) {
        _events[day] = [];
      }
      _events[day]!.add(event);
    }
    notifyListeners();
  }

  Future<void> addEvent(Event event) async {
    await eventRepository.addEvent(event);
    await getEvents(); // Muat ulang semua event
  }

  Future<void> updateEvent(Event event) async {
    await eventRepository.updateEvent(event);
    await getEvents();
  }

  Future<void> deleteEvent(int id) async {
    await eventRepository.deleteEvent(id);
    await getEvents();
  }
}
