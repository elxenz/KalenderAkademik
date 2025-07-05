import 'package:flutter/material.dart';

// Enum untuk aturan perulangan tetap di sini karena ini adalah bagian dari logika domain
enum RecurrenceRule { none, daily, weekly, monthly }

class Event {
  final int? id;
  final String title;
  final String description;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int colorValue;
  final bool isRecurring;
  final RecurrenceRule recurrenceRule;

  Event({
    this.id,
    required this.title,
    this.description = '',
    required this.date,
    required this.startTime,
    required this.endTime,
    this.colorValue = 0xFF4285F4,
    this.isRecurring = false,
    this.recurrenceRule = RecurrenceRule.none,
  });

  Color get color => Color(colorValue);

  // Kita akan memindahkan logika toMap dan fromMap ke lapisan Data
}
