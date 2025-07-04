import 'package:flutter/material.dart';

class Event {
  final int? id;
  final String title;
  final String description; // Tambahan baru
  final DateTime date;
  final String startTime;
  final String endTime;
  final int colorValue; // Tambahan baru untuk menyimpan nilai warna

  Event({
    this.id,
    required this.title,
    this.description = '', // Nilai default
    required this.date,
    required this.startTime,
    required this.endTime,
    this.colorValue = 0xFF4285F4, // Warna biru Google sebagai default
  });

  // Helper untuk mendapatkan objek Color
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String().split('T').first,
      'startTime': startTime,
      'endTime': endTime,
      'colorValue': colorValue,
    };
  }

  @override
  String toString() {
    return title;
  }
}
