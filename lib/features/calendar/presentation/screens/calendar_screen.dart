// lib/features/calendar/presentation/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:kalender/core/utils/database_helper.dart';
import 'package:kalender/core/utils/notification_helper.dart';
import '../../domain/entities/event.dart';
import 'edit_event_screen.dart';
import '../widgets/event_search_delegate.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationHelper _notificationHelper = NotificationHelper();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _eventsSource = {};
  bool _isAgendaView = false;
  List<Event> _allFutureEvents = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);
    _loadEventsFromDb();
  }

  Future<void> _loadEventsFromDb() async {
    _onDaySelected(_selectedDay!, _focusedDay);
    final allEvents = await _dbHelper.getAllEvents();
    final events = <DateTime, List<Event>>{};
    final futureEvents = <Event>[];
    for (final event in allEvents) {
      final day =
          DateTime.utc(event.date.year, event.date.month, event.date.day);
      if (events[day] == null) {
        events[day] = [];
      }
      events[day]!.add(event);
      if (!event.date
          .isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        futureEvents.add(event);
      }
    }
    futureEvents.sort((a, b) => a.date.compareTo(b.date));
    setState(() {
      _eventsSource = events;
      _allFutureEvents = futureEvents;
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
    final eventDateToManage = event?.date ?? _selectedDay!;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditEventScreen(event: event)),
    );

    if (result != null && result is Map<String, dynamic>) {
      final title = result['title'] as String;
      final description = result['description'] as String;
      final startTimeStr = result['startTime'] as String;
      final endTimeStr = result['endTime'] as String;
      final colorValue = int.parse(result['colorValue'] as String);

      final startTime = TimeOfDay(
          hour: int.parse(startTimeStr.split(':')[0]),
          minute: int.parse(startTimeStr.split(':')[1]));

      final scheduledNotificationTime = DateTime(
              eventDateToManage.year,
              eventDateToManage.month,
              eventDateToManage.day,
              startTime.hour,
              startTime.minute)
          .subtract(const Duration(minutes: 10));

      if (event != null) {
        final updatedEvent = Event(
            id: event.id,
            title: title,
            description: description,
            date: eventDateToManage,
            startTime: startTimeStr,
            endTime: endTimeStr,
            colorValue: colorValue);
        await _dbHelper.updateEvent(updatedEvent);
        await _notificationHelper.scheduleNotification(
          id: updatedEvent.id!,
          title: 'Pengingat: ${updatedEvent.title}',
          body: 'Acara Anda akan dimulai dalam 10 menit.',
          scheduledTime: scheduledNotificationTime,
        );
      } else {
        final newEvent = Event(
            title: title,
            description: description,
            date: eventDateToManage,
            startTime: startTimeStr,
            endTime: endTimeStr,
            colorValue: colorValue);
        final newId = await _dbHelper.insertEvent(newEvent);
        await _notificationHelper.scheduleNotification(
          id: newId,
          title: 'Pengingat: $title',
          body: 'Acara Anda akan dimulai dalam 10 menit.',
          scheduledTime: scheduledNotificationTime,
        );
      }
      _loadEventsFromDb();
    }
  }

  void _deleteEvent(int id) async {
    await _dbHelper.deleteEvent(id);
    await _notificationHelper.cancelNotification(id);
    _loadEventsFromDb();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              // --- PERBAIKAN DI SINI ---
              final Event? selectedEvent = await showSearch<Event?>(
                context: context,
                delegate: EventSearchDelegate(),
              );
              // -------------------------

              if (selectedEvent != null) {
                setState(() {
                  _isAgendaView = false;
                  _focusedDay = selectedEvent.date;
                  _selectedDay = selectedEvent.date;
                });
                _onDaySelected(selectedEvent.date, selectedEvent.date);
              }
            },
          ),
          IconButton(
            icon:
                Icon(_isAgendaView ? Icons.calendar_month : Icons.view_agenda),
            onPressed: () => setState(() => _isAgendaView = !_isAgendaView),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isAgendaView)
            TableCalendar<Event>(
              locale: 'id_ID',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              eventLoader: _getEventsForDay,
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() => _calendarFormat = format);
                }
              },
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: _buildEventsMarker(date, events),
                    );
                  }
                  return null;
                },
              ),
            ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _isAgendaView ? _buildAgendaView() : _buildDayEventsView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateAndManageEvent(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventsMarker(DateTime date, List<Event> events) {
    return Container(
      decoration:
          BoxDecoration(shape: BoxShape.circle, color: events.first.color),
      width: 7.0,
      height: 7.0,
    );
  }

  Widget _buildDayEventsView() {
    return ValueListenableBuilder<List<Event>>(
      valueListenable: _selectedEvents,
      builder: (context, value, _) {
        if (value.isEmpty) {
          return const Center(child: Text("Tidak ada acara di tanggal ini."));
        }
        return ListView.builder(
          itemCount: value.length,
          itemBuilder: (context, index) {
            final event = value[index];
            return Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 8, color: event.color),
                    Expanded(
                      child: ListTile(
                        onTap: () => _navigateAndManageEvent(event: event),
                        title: Text(event.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: event.description.isNotEmpty
                            ? Text(event.description,
                                maxLines: 1, overflow: TextOverflow.ellipsis)
                            : null,
                        leading: Text("${event.startTime}\n${event.endTime}",
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () => _deleteEvent(event.id!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAgendaView() {
    if (_allFutureEvents.isEmpty) {
      return const Center(child: Text("Tidak ada acara mendatang."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _allFutureEvents.length,
      itemBuilder: (context, index) {
        final event = _allFutureEvents[index];
        final eventDate =
            DateFormat('EEEE, d MMMM y', 'id_ID').format(event.date);
        final bool showHeader = index == 0 ||
            !isSameDay(_allFutureEvents[index - 1].date, event.date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader)
              Padding(
                padding:
                    const EdgeInsets.only(left: 8.0, top: 16.0, bottom: 8.0),
                child: Text(eventDate,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            Card(
              color: event.color.withAlpha(50),
              child: ListTile(
                onTap: () => _navigateAndManageEvent(event: event),
                leading: Text(event.startTime,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                title: Text(event.title),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              ),
            ),
          ],
        );
      },
    );
  }
}
