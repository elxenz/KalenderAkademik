import '../entities/event.dart';

abstract class EventRepository {
  Future<List<Event>> getAllEvents();
  Future<int> addEvent(Event event);
  Future<void> updateEvent(Event event);
  Future<void> deleteEvent(int id);
  Future<List<Event>> searchEvents(String query);
}
