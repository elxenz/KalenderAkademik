import 'package:kalender/features/calendar/domain/entities/event.dart';

abstract class EventRepository {
  Future<List<Event>> getAllEvents();
  Future<List<Event>> getEventsForMonth(DateTime date);
  Future<List<Event>> searchEvents(String query);
  Future<int> addEvent(Event event);
  Future<void> updateEvent(Event event);
  Future<void> deleteEvent(int id);
}
