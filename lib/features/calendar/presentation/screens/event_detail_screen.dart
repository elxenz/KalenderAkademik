import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kalender/features/calendar/domain/entities/event.dart';
import 'edit_event_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Helper untuk memformat tanggal dan waktu
    final String formattedDate =
        DateFormat('EEEE, d MMMM y', 'id_ID').format(event.date);
    final String formattedTime = '${event.startTime} - ${event.endTime}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Acara'),
        backgroundColor:
            event.color, // Gunakan warna acara sebagai latar belakang AppBar
        actions: [
          // Tombol untuk masuk ke mode edit
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // Navigasi ke halaman edit dan tunggu hasilnya
              final bool? result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditEventScreen(event: event),
                ),
              );

              // Jika hasil edit adalah 'true', tutup halaman detail agar halaman utama me-refresh
              if (result == true) {
                // ignore: use_build_context_synchronously
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          // Menampilkan Judul Acara
          Text(
            event.title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Menampilkan Waktu
          _buildDetailRow(
            context,
            icon: Icons.access_time_filled,
            title: formattedDate,
            subtitle: formattedTime,
          ),

          // Menampilkan Deskripsi (jika ada)
          if (event.description.isNotEmpty)
            _buildDetailRow(
              context,
              icon: Icons.description_outlined,
              title: 'Deskripsi',
              subtitle: event.description,
            ),

          // Menampilkan Warna Acara
          _buildDetailRow(
            context,
            icon: Icons.color_lens,
            title: 'Warna Acara',
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: event.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper untuk membuat baris detail yang konsisten
  Widget _buildDetailRow(BuildContext context,
      {required IconData icon,
      required String title,
      String? subtitle,
      Widget? child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade700),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey.shade600)),
                  ),
                if (child != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: child,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
