// lib/features/calendar/presentation/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:kalender/core/utils/database_helper.dart';
import '../../domain/entities/event.dart';
import 'edit_event_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _eventsSource = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);
    _loadEventsFromDb();
  }

  Future<void> _loadEventsFromDb() async {
    _onDaySelected(_selectedDay!, _focusedDay);

    final allEvents = await _dbHelper.getEventsForDay(DateTime(2000));
    final events = <DateTime, List<Event>>{};
    for (final event in allEvents) {
      final day = DateTime.utc(
        event.date.year,
        event.date.month,
        event.date.day,
      );
      if (events[day] == null) {
        events[day] = [];
      }
      events[day]!.add(event);
    }
    setState(() {
      _eventsSource = events;
    });
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _eventsSource[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
    _selectedEvents.value = await _dbHelper.getEventsForDay(selectedDay);
  }

  void _navigateAndManageEvent({Event? event}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditEventScreen(event: event)),
    );

    if (result != null && result is Map<String, String>) {
      if (event != null) {
        final updatedEvent = Event(
          id: event.id,
          title: result['title']!,
          date: _selectedDay!,
          startTime: result['startTime']!,
          endTime: result['endTime']!,
        );
        await _dbHelper.updateEvent(updatedEvent);
      } else {
        final newEvent = Event(
          title: result['title']!,
          date: _selectedDay!,
          startTime: result['startTime']!,
          endTime: result['endTime']!,
        );
        await _dbHelper.insertEvent(newEvent);
      }
      _loadEventsFromDb();
    }
  }

  void _deleteEvent(int id) async {
    await _dbHelper.deleteEvent(id);
    _loadEventsFromDb();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalender')),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            eventLoader: _getEventsForDay,
            onFormatChanged: (format) {
              // --- PERBAIKAN DI SINI ---
              if (_calendarFormat != format) {
                setState(() => _calendarFormat = format);
              }
              // --------------------------
            },
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: true,
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue.withAlpha(77),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final event = value[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        onTap: () => _navigateAndManageEvent(event: event),
                        title: Text(event.title),
                        subtitle: Text('${event.startTime} - ${event.endTime}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteEvent(event.id!),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateAndManageEvent(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
