import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kalender/features/calendar/domain/entities/event.dart';
import 'package:kalender/features/calendar/domain/repositories/event_repository.dart';

class EventSearchDelegate extends SearchDelegate<Event?> {
  final EventRepository eventRepository;

  EventSearchDelegate({required this.eventRepository});

  @override
  String get searchFieldLabel => 'Cari acara...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<Event>>(
      future: eventRepository.searchEvents(query),
      builder: (context, snapshot) {
        if (query.isEmpty) {
          return const Center(
              child: Text('Silakan ketik untuk mencari acara.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Tidak ada acara yang ditemukan.'));
        }

        final results = snapshot.data!;
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final event = results[index];
            return ListTile(
              leading: Icon(Icons.circle, color: event.color, size: 20),
              title: Text(event.title),
              subtitle: Text(
                  DateFormat('EEEE, d MMMM y', 'id_ID').format(event.date)),
              onTap: () {
                close(context, event);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
