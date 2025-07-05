import 'package:kalender/features/calendar/data/datasources/event_local_datasource.dart';
import 'package:kalender/features/calendar/data/models/event_model.dart'
    as model;
import 'package:kalender/features/calendar/domain/entities/event.dart';
import 'package:kalender/features/calendar/domain/repositories/event_repository.dart';

class EventRepositoryImpl implements EventRepository {
  // Pastikan EventLocalDataSource adalah tipe yang dikenal
  final EventLocalDataSource localDataSource;

  EventRepositoryImpl({required this.localDataSource});

  @override
  Future<int> addEvent(Event event) async {
    final eventModel = model.EventModel.fromEntity(event);
    return await localDataSource.addEvent(eventModel);
  }

  @override
  Future<void> deleteEvent(int id) async {
    await localDataSource.deleteEvent(id);
  }

  @override
  Future<List<Event>> getAllEvents() async {
    final eventModels = await localDataSource.getEvents();
    return eventModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Event>> getEventsForMonth(DateTime month) async {
    final eventModels = await localDataSource.getEventsForMonth(month);
    return eventModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Event>> searchEvents(String query) async {
    final eventModels = await localDataSource.searchEvents(query);
    return eventModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> updateEvent(Event event) async {
    final eventModel = model.EventModel.fromEntity(event);
    await localDataSource.updateEvent(eventModel);
  }
}

// Catatan: Pastikan EventModel Anda memiliki method fromEntity dan toEntity
// contoh di lib/features/calendar/data/models/event_model.dart
/*
  factory EventModel.fromEntity(Event event) {
    return EventModel(id: event.id, ...);
  }

  Event toEntity() {
    return Event(id: id, ...);
  }
*/
