import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kalender/features/calendar/domain/entities/event.dart';
import 'package:kalender/features/calendar/presentation/provider/event_provider.dart';
import 'package:kalender/features/calendar/presentation/screens/edit_event_screen.dart';
import 'package:kalender/features/calendar/presentation/screens/event_detail_screen.dart';
import 'package:kalender/features/calendar/presentation/widgets/app_drawer.dart';
import 'package:kalender/features/calendar/presentation/widgets/event_search_delegate.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  /*  */
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan Watch untuk rebuild saat data berubah
    final eventProvider = context.watch<EventProvider>();
    final selectedEvents = eventProvider.getEventsForDay(_selectedDay!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final Event? selected = await showSearch(
                context: context,
                delegate: EventSearchDelegate(
                    events:
                        eventProvider.events.values.expand((e) => e).toList()),
              );

              if (selected != null && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => EventDetailScreen(event: selected)),
                );
              }
            },
          ),
        ],
      ),
      // Panggil sebagai constructor
      drawer: const AppDrawer(),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: eventProvider.getEventsForDay,
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              itemCount: selectedEvents.length,
              itemBuilder: (context, index) {
                final event = selectedEvents[index];
                return ListTile(
                  title: Text(event.title),
                  subtitle: Text(DateFormat.jm().format(DateTime(
                      event.date.year,
                      event.date.month,
                      event.date.day,
                      event.startTime.hour,
                      event.startTime.minute))),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EventDetailScreen(event: event)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigasi ke halaman edit dan tunggu hasilnya
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => EditEventScreen(date: _selectedDay)),
          );
          // Jika hasilnya true (ada perubahan), muat ulang event
          if (result == true && mounted) {
            context.read<EventProvider>().getEvents();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
