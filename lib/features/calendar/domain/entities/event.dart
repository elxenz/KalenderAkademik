// lib/features/calendar/domain/entities/event.dart
class Event {
  final int? id;
  final String title;
  final DateTime date;
  final String startTime; // Simpan waktu sebagai String "HH:mm"
  final String endTime;

  Event({
    this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date':
          date
              .toIso8601String()
              .split('T')
              .first, // Hanya simpan tanggal YYYY-MM-DD
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  @override
  String toString() {
    return title; // Cukup tampilkan judul
  }
}
