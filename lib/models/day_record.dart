import 'package:flutter/material.dart';
import 'meal_entry.dart';

class DayRecord {
  final String dateKey;
  final List<MealEntry> entries;

  DayRecord({required this.dateKey, List<MealEntry>? entries})
      : entries = entries ?? _defaults();

  static List<MealEntry> _defaults() => [
    MealEntry(name: MealType.breakfast.label, type: MealType.breakfast,
        doseTime: const TimeOfDay(hour: 7,  minute: 0),
        mealTime: const TimeOfDay(hour: 7,  minute: 30)),
    MealEntry(name: MealType.lunch.label, type: MealType.lunch,
        doseTime: const TimeOfDay(hour: 12, minute: 0),
        mealTime: const TimeOfDay(hour: 12, minute: 30)),
    MealEntry(name: MealType.dinner.label, type: MealType.dinner,
        doseTime: const TimeOfDay(hour: 19, minute: 0),
        mealTime: const TimeOfDay(hour: 19, minute: 30)),
  ];

  /// Somme des doses saisies directement (telles quelles)
  double get totalDose =>
      entries.fold(0.0, (s, e) => s + (e.dose ?? 0.0));

  /// Moyenne des mesures glycémie après conversion (règle 0.18)
  double get averageGlycemieAffichee {
    final valid = entries.where((e) => e.glycemieAffichee != null);
    if (valid.isEmpty) return 0;
    return valid.fold(0.0, (s, e) => s + e.glycemieAffichee!) / valid.length;
  }

  Map<String, dynamic> toJson() => {
    'dateKey': dateKey,
    'entries': entries.map((e) => e.toJson()).toList(),
  };

  factory DayRecord.fromJson(Map<String, dynamic> j) => DayRecord(
    dateKey: j['dateKey'] as String,
    entries: (j['entries'] as List)
        .map((e) => MealEntry.fromJson(e as Map<String, dynamic>)).toList(),
  );

  factory DayRecord.fromSupabase(Map<String, dynamic> j) => DayRecord(
    dateKey: j['date_key'] as String,
    entries: (j['entries'] as List)
        .map((e) => MealEntry.fromJson(e as Map<String, dynamic>)).toList(),
  );
}