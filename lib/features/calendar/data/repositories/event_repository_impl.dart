import 'package:kalender/features/calendar/domain/entities/event.dart';
import 'package:kalender/features/calendar/domain/repositories/event_repository.dart';
import 'package:kalender/features/calendar/data/datasources/event_local_datasource.dart';
import 'package:kalender/features/calendar/data/models/event_model.dart';

class EventRepositoryImpl implements EventRepository {
  final EventLocalDataSource localDataSource;

  EventRepositoryImpl({required this.localDataSource});

  @override
  Future<void> addEvent(Event event) async {
    final eventModel = EventModel(
      title: event.title,
      description: event.description,
      date: event.date,
      startTime: event.startTime,
      endTime: event.endTime,
      colorValue: event.colorValue,
      isRecurring: event.isRecurring,
      recurrenceRule: event.recurrenceRule,
    );
    await localDataSource.insertEvent(eventModel);
  }

  @override
  Future<void> deleteEvent(int id) async {
    await localDataSource.deleteEvent(id);
  }

  @override
  Future<List<Event>> getAllEvents() async {
    final eventModels = await localDataSource.getAllEvents();
    return eventModels.map((model) => model as Event).toList();
  }

  @override
  Future<List<Event>> searchEvents(String query) async {
    final eventModels = await localDataSource.searchEvents(query);
    return eventModels.map((model) => model as Event).toList();
  }

  @override
  Future<void> updateEvent(Event event) async {
    final eventModel = EventModel(
      id: event.id,
      title: event.title,
      description: event.description,
      date: event.date,
      startTime: event.startTime,
      endTime: event.endTime,
      colorValue: event.colorValue,
      isRecurring: event.isRecurring,
      recurrenceRule: event.recurrenceRule,
    );
    await localDataSource.updateEvent(eventModel);
  }
}
