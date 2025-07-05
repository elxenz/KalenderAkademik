import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:kalender/features/calendar/data/datasources/event_local_datasource.dart';
import 'package:kalender/features/calendar/data/repositories/event_repository_impl.dart';
import 'package:kalender/core/utils/notification_helper.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import 'edit_event_screen.dart';
import '../widgets/app_drawer.dart';
import '../widgets/event_search_delegate.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final ValueNotifier<List<Event>> _selectedEvents;
  late final EventRepository _eventRepository;
  final NotificationHelper _notificationHelper = NotificationHelper();

  CalendarView _currentView = CalendarView.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _eventsSource = {};
  List<Event> _allFutureEvents = [];

  @override
  void initState() {
    super.initState();
    // Inisialisasi repository dengan implementasinya, menggantikan DatabaseHelper
    _eventRepository =
        EventRepositoryImpl(localDataSource: EventLocalDataSourceImpl());

    initializeDateFormatting('id_ID', null);
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);
    _loadEventsFromDb();
  }

  Future<void> _loadEventsFromDb() async {
    final allEvents =
        await _eventRepository.getAllEvents(); // Menggunakan repository
    final events = <DateTime, List<Event>>{};
    final recurrenceEndDate = DateTime.now().add(const Duration(days: 365));

    for (final event in allEvents) {
      if (!event.isRecurring) {
        final day =
            DateTime.utc(event.date.year, event.date.month, event.date.day);
        if (events[day] == null) events[day] = [];
        events[day]!.add(event);
      } else {
        DateTime currentDate = event.date;
        while (currentDate.isBefore(recurrenceEndDate)) {
          final day = DateTime.utc(
              currentDate.year, currentDate.month, currentDate.day);
          if (events[day] == null) events[day] = [];
          events[day]!.add(Event(
            id: event.id,
            title: event.title,
            description: event.description,
            date: currentDate,
            startTime: event.startTime,
            endTime: event.endTime,
            colorValue: event.colorValue,
            isRecurring: true,
            recurrenceRule: event.recurrenceRule,
          ));
          switch (event.recurrenceRule) {
            case RecurrenceRule.daily:
              currentDate = currentDate.add(const Duration(days: 1));
              break;
            case RecurrenceRule.weekly:
              currentDate = currentDate.add(const Duration(days: 7));
              break;
            case RecurrenceRule.monthly:
              currentDate = DateTime(
                  currentDate.year, currentDate.month + 1, currentDate.day);
              break;
            case RecurrenceRule.none:
              break;
          }
        }
      }
    }

    setState(() {
      _eventsSource = events;
      _updateAgendaView();
    });
    _onDaySelected(_selectedDay!, _focusedDay);
  }

  void _updateAgendaView() {
    final futureEvents = <Event>[];
    _eventsSource.forEach((date, events) {
      if (!date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        futureEvents.addAll(events);
      }
    });
    futureEvents.sort((a, b) {
      int dateComp = a.date.compareTo(b.date);
      if (dateComp != 0) return dateComp;
      return a.startTime.compareTo(b.startTime);
    });
    _allFutureEvents = futureEvents;
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Event> _getEventsForDay(DateTime day) =>
      _eventsSource[DateTime.utc(day.year, day.month, day.day)] ?? [];

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
    _selectedEvents.value = _getEventsForDay(selectedDay);
  }

  void _navigateAndManageEvent({Event? event}) async {
    final eventDateToManage = event?.date ?? _selectedDay!;
    final result = await Navigator.push(context,
        MaterialPageRoute(builder: (context) => EditEventScreen(event: event)));
    if (result != null && result is Map<String, dynamic>) {
      final title = result['title'] as String;
      final description = result['description'] as String;
      final startTimeStr = result['startTime'] as String;
      final endTimeStr = result['endTime'] as String;
      final colorValue = result['colorValue'] as int;
      final isRecurring = result['isRecurring'] as bool;
      final recurrenceRule = result['recurrenceRule'] as RecurrenceRule;

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
          date: event.date,
          startTime: startTimeStr,
          endTime: endTimeStr,
          colorValue: colorValue,
          isRecurring: isRecurring,
          recurrenceRule: recurrenceRule,
        );
        await _eventRepository.updateEvent(updatedEvent);
        await _notificationHelper.scheduleNotification(
            id: updatedEvent.id!,
            title: 'Pengingat: ${updatedEvent.title}',
            body: 'Acara Anda akan dimulai dalam 10 menit.',
            scheduledTime: scheduledNotificationTime);
      } else {
        final newEvent = Event(
          title: title,
          description: description,
          date: eventDateToManage,
          startTime: startTimeStr,
          endTime: endTimeStr,
          colorValue: colorValue,
          isRecurring: isRecurring,
          recurrenceRule: recurrenceRule,
        );
        await _eventRepository.addEvent(newEvent);
        // Notifikasi untuk acara baru bisa ditambahkan di sini jika addEvent mengembalikan ID
      }
      _loadEventsFromDb();
    }
  }

  void _deleteEvent(Event event) async {
    await _eventRepository.deleteEvent(event.id!);
    await _notificationHelper.cancelNotification(event.id!);
    _loadEventsFromDb();
  }

  void _changeView(CalendarView view) {
    Navigator.pop(context);
    setState(() {
      _currentView = view;
    });
  }

  CalendarFormat get calendarFormat {
    switch (_currentView) {
      case CalendarView.week:
        return CalendarFormat.week;
      case CalendarView.month:
        return CalendarFormat.month;
      case CalendarView.agenda:
        return CalendarFormat.month;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool showCalendar = _currentView != CalendarView.agenda;
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(onTampilanSelected: _changeView),
      appBar: AppBar(
        title: Text('Kalender - Tampilan ${_currentView.name.capitalize()}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final Event? selectedEvent = await showSearch<Event?>(
                context: context,
                delegate: EventSearchDelegate(
                    eventRepository: _eventRepository), // Kirim repository
              );
              if (selectedEvent != null) {
                setState(() {
                  _currentView = CalendarView.month;
                  _focusedDay = selectedEvent.date;
                  _selectedDay = selectedEvent.date;
                });
                _onDaySelected(selectedEvent.date, selectedEvent.date);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (showCalendar)
            TableCalendar<Event>(
              locale: 'id_ID',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: calendarFormat,
              availableGestures: AvailableGestures.all,
              headerStyle: const HeaderStyle(
                  formatButtonVisible: false, titleCentered: true),
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              eventLoader: _getEventsForDay,
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                        right: 1,
                        bottom: 1,
                        child: _buildEventsMarker(date, events));
                  }
                  return null;
                },
              ),
            ),
          const SizedBox(height: 8.0),
          Expanded(
            child: showCalendar ? _buildDayEventsView() : _buildAgendaView(),
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
        value.sort((a, b) => a.startTime.compareTo(b.startTime));
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
                          onPressed: () => _deleteEvent(event),
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

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
