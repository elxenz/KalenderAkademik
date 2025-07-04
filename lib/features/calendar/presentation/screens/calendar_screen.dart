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

// Enum untuk mengelola jenis tampilan kalender yang aktif di drawer
enum CalendarViewType {
  schedule,
  day, // Menambahkan Day
  week,
  month,
  year, // Menambahkan Year
}

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
  CalendarViewType _activeView = CalendarViewType.month; // Default view
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

  // Fungsi pembantu untuk membuat ListTile tampilan
  Widget _buildViewOptionTile(String title, CalendarViewType viewType) {
    bool isSelected = _activeView == viewType;
    return ListTile(
      leading: Icon(
        _getViewIcon(viewType),
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context)
          .colorScheme
          .primaryContainer
          .withAlpha((255 * 0.4).round()), // Menggunakan withAlpha
      onTap: () {
        setState(() {
          _activeView = viewType;
          // Mengatur tampilan berdasarkan pilihan dari sidebar
          if (viewType == CalendarViewType.schedule ||
              viewType == CalendarViewType.day ||
              viewType == CalendarViewType.year) {
            _isAgendaView =
                true; // Untuk Schedule, Day, Year, tampilkan agenda view
            // Tampilkan pesan informasi jika memilih Day atau Year karena TableCalendar tidak mendukungnya secara visual
            if (viewType == CalendarViewType.day ||
                viewType == CalendarViewType.year) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Tampilan "${title}" tidak didukung secara visual oleh kalender utama, menampilkan daftar acara.'),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } else {
            _isAgendaView =
                false; // Untuk Month dan Week, tampilkan TableCalendar
            if (viewType == CalendarViewType.month) {
              _calendarFormat = CalendarFormat.month;
            } else if (viewType == CalendarViewType.week) {
              _calendarFormat = CalendarFormat.week;
            }
          }
        });
        Navigator.pop(context); // Tutup drawer
      },
    );
  }

  IconData _getViewIcon(CalendarViewType viewType) {
    switch (viewType) {
      case CalendarViewType.schedule:
        return Icons.event_note;
      case CalendarViewType.day:
        return Icons.calendar_view_day;
      case CalendarViewType.week:
        return Icons.calendar_view_week;
      case CalendarViewType.month:
        return Icons.calendar_view_month;
      case CalendarViewType.year:
        return Icons.calendar_today; // Ikon untuk tampilan tahun
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kalender',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final Event? selectedEvent = await showSearch<Event?>(
                context: context,
                delegate: EventSearchDelegate(),
              );

              if (selectedEvent != null) {
                setState(() {
                  _isAgendaView = false;
                  _focusedDay = selectedEvent.date;
                  _selectedDay = selectedEvent.date;
                  _activeView = CalendarViewType
                      .month; // Kembali ke tampilan bulan saat mencari
                });
                _onDaySelected(selectedEvent.date, selectedEvent.date);
              }
            },
          ),
          IconButton(
            icon:
                Icon(_isAgendaView ? Icons.calendar_month : Icons.view_agenda),
            onPressed: () {
              setState(() {
                _isAgendaView = !_isAgendaView;
                _activeView = _isAgendaView
                    ? CalendarViewType.schedule
                    : CalendarViewType.month;
              });
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Kalender Akademik', // Menggunakan judul dari contoh gambar
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(
                      height: 8.0), // Menjaga sedikit spasi jika diperlukan
                ],
              ),
            ),
            // Opsi tampilan tanggal
            _buildViewOptionTile('Schedule', CalendarViewType.schedule),
            _buildViewOptionTile('Day', CalendarViewType.day),
            _buildViewOptionTile('Week', CalendarViewType.week),
            _buildViewOptionTile('Month', CalendarViewType.month),
            _buildViewOptionTile('Year', CalendarViewType.year),
            Divider(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha((255 * 0.1).round())),
            ListTile(
              leading: Icon(Icons.refresh,
                  color: Theme.of(context).colorScheme.onSurface),
              title:
                  Text('Refresh', style: Theme.of(context).textTheme.bodyLarge),
              onTap: () {
                _loadEventsFromDb();
                Navigator.pop(context); // Tutup drawer setelah refresh
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kalender diperbarui!')),
                );
              },
            ),
            Divider(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha((255 * 0.1).round())),
            ListTile(
              leading: Icon(Icons.settings,
                  color: Theme.of(context).colorScheme.onSurface),
              title: Text('Settings',
                  style: Theme.of(context).textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context); // Tutup drawer
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Navigasi ke Pengaturan (belum diimplementasikan)')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline,
                  color: Theme.of(context).colorScheme.onSurface),
              title: Text('Help & feedback',
                  style: Theme.of(context).textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context); // Tutup drawer
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Navigasi ke Bantuan & Umpan Balik (belum diimplementasikan)')),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // TableCalendar hanya ditampilkan jika bukan Agenda View
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
                  setState(() {
                    // Logika untuk menghilangkan "2 weeks" dan menyesuaikan format
                    if (format == CalendarFormat.twoWeeks) {
                      _calendarFormat = CalendarFormat
                          .week; // Ganti ke Week jika 2 Weeks yang dipilih
                      _activeView = CalendarViewType.week;
                    } else {
                      _calendarFormat = format;
                      if (format == CalendarFormat.month) {
                        _activeView = CalendarViewType.month;
                      } else if (format == CalendarFormat.week) {
                        _activeView = CalendarViewType.week;
                      }
                    }
                  });
                }
              },
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final events = _getEventsForDay(day);
                  bool isToday = isSameDay(day, DateTime.now());
                  bool isSelected = isSameDay(day, _selectedDay);

                  BoxDecoration dayDecoration;
                  TextStyle dayTextStyle;

                  // Gaya untuk hari terpilih
                  if (isSelected) {
                    dayDecoration = BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    );
                    dayTextStyle = Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold);
                  }
                  // Gaya untuk hari ini
                  else if (isToday) {
                    dayDecoration = BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withAlpha(
                          (255 * 0.5).round()), // Menggunakan withAlpha
                      shape: BoxShape.circle,
                    );
                    dayTextStyle = Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold);
                  }
                  // Gaya default untuk hari lainnya
                  else {
                    dayDecoration = const BoxDecoration();
                    dayTextStyle = Theme.of(context).textTheme.bodyLarge!;
                    // Gaya untuk akhir pekan
                    if (day.weekday == DateTime.saturday ||
                        day.weekday == DateTime.sunday) {
                      dayTextStyle = dayTextStyle.copyWith(color: Colors.red);
                    }
                  }

                  return Container(
                    margin:
                        const EdgeInsets.all(4.0), // Margin untuk setiap sel
                    decoration: isSelected
                        ? BoxDecoration(
                            // Border jika terpilih
                            border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2),
                            borderRadius: BorderRadius.circular(8.0),
                          )
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: const EdgeInsets.only(
                                top: 4.0, bottom: 2.0), // Margin lebih kecil
                            decoration: dayDecoration,
                            width: 24, // Ukuran lingkaran tanggal
                            height: 24,
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: dayTextStyle.copyWith(
                                  fontSize: 12.0), // Ukuran font tanggal
                            ),
                          ),
                        ),
                        if (events.isNotEmpty)
                          Expanded(
                            // Memungkinkan event mengambil sisa ruang
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(), // Nonaktifkan scroll di dalam sel
                              itemCount: events.length > 2
                                  ? 2
                                  : events
                                      .length, // Batasi 2 event yang terlihat
                              itemBuilder: (context, index) {
                                final event = events[index];
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 1.0, vertical: 0.5),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 3.0, vertical: 1.0),
                                  decoration: BoxDecoration(
                                    color: event.color.withAlpha((255 * 0.8)
                                        .round()), // Menggunakan withAlpha
                                    borderRadius: BorderRadius.circular(3.0),
                                  ),
                                  child: Text(
                                    event.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                          color: Colors.white,
                                          fontSize:
                                              7.0, // Ukuran font event di sel
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        if (events.length >
                            2) // Indikator jika ada lebih banyak event
                          Padding(
                            padding: const EdgeInsets.only(top: 1.0),
                            child: Text(
                              '+${events.length - 2} lagi',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                      fontSize: 7.0, color: Colors.grey[700]),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              headerStyle: HeaderStyle(
                // Mengatur gaya header
                formatButtonVisible:
                    true, // Pastikan tombol format bawaan terlihat atau disembunyikan sesuai keinginan Anda
                titleCentered: true,
                titleTextStyle: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(fontWeight: FontWeight.bold),
                leftChevronIcon: Icon(Icons.chevron_left,
                    color: Theme.of(context).colorScheme.primary),
                rightChevronIcon: Icon(Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary),
                formatButtonDecoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withAlpha((255 * 0.4).round()), // Menggunakan withAlpha
                  borderRadius: BorderRadius.circular(20.0),
                ),
                formatButtonTextStyle:
                    Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
              ),
              calendarStyle: CalendarStyle(
                // Mengatur gaya kalender
                outsideDaysVisible: true,
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
        backgroundColor:
            Theme.of(context).colorScheme.primary, // Sesuaikan warna FAB
        child: const Icon(Icons.add,
            color: Colors.white), // Sesuaikan warna ikon FAB
      ),
    );
  }

  Widget _buildDayEventsView() {
    return ValueListenableBuilder<List<Event>>(
      valueListenable: _selectedEvents,
      builder: (context, value, _) {
        if (value.isEmpty) {
          return const Center(
            child: Text(
              "Tidak ada acara di tanggal ini.",
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          itemCount: value.length,
          itemBuilder: (context, index) {
            final event = value[index];
            return Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 4.0, // Memberikan bayangan halus
              child: InkWell(
                // Menambahkan efek ripple pada ketukan
                onTap: () => _navigateAndManageEvent(event: event),
                borderRadius: BorderRadius.circular(12.0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 8,
                        decoration: BoxDecoration(
                          color: event.color,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12.0),
                            bottomLeft: Radius.circular(12.0),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(
                              8.0), // Padding di dalam kartu
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                event.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                              ),
                              if (event.description.isNotEmpty)
                                const SizedBox(height: 4.0),
                              if (event.description.isNotEmpty)
                                Text(
                                  event.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withAlpha((255 * 0.7)
                                                .round()), // Menggunakan withAlpha
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              event.startTime,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            Text(
                              event.endTime,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withAlpha((255 * 0.6)
                                            .round()), // Menggunakan withAlpha
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () => _deleteEvent(event.id!),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAgendaView() {
    // Filter _allFutureEvents berdasarkan _activeView jika diperlukan
    List<Event> filteredEvents = [];
    if (_activeView == CalendarViewType.day) {
      // Filter event untuk hari yang dipilih
      filteredEvents = _allFutureEvents
          .where((event) => isSameDay(event.date, _selectedDay!))
          .toList();
    } else if (_activeView == CalendarViewType.year) {
      // Filter event untuk tahun yang dipilih
      filteredEvents = _allFutureEvents
          .where((event) => event.date.year == _focusedDay.year)
          .toList();
    } else {
      // Untuk Schedule view (default agenda), tampilkan semua future events
      filteredEvents = _allFutureEvents;
    }

    if (filteredEvents.isEmpty) {
      return const Center(
        child: Text(
          "Tidak ada acara mendatang.",
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        final eventDate =
            DateFormat('EEEE, d MMMM y', 'id_ID').format(event.date);
        final bool showHeader = index == 0 ||
            !isSameDay(filteredEvents[index - 1].date, event.date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader)
              Padding(
                padding:
                    const EdgeInsets.only(left: 8.0, top: 16.0, bottom: 8.0),
                child: Text(
                  eventDate,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
            Card(
              color: event.color.withAlpha(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 2.0, // Bayangan lebih ringan untuk agenda
              child: ListTile(
                onTap: () => _navigateAndManageEvent(event: event),
                leading: Text(
                  event.startTime,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                title: Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(
                        (255 * 0.6).round())), // Menggunakan withAlpha
              ),
            ),
            if (showHeader)
              const Divider(
                  indent: 8.0,
                  endIndent: 8.0,
                  height: 16.0), // Garis pemisah setelah header
          ],
        );
      },
    );
  }
}
