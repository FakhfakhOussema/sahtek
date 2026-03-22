import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/day_record.dart';
import '../models/meal_entry.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';

class AppProvider extends ChangeNotifier {
  final Map<String, DayRecord> _records = {};
  DateTime _selectedDate = DateTime.now();
  bool _notificationsEnabled = true;
  bool _loaded = false;
  bool _syncing = false;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get loaded => _loaded;
  bool get syncing => _syncing;
  DateTime get selectedDate => _selectedDate;

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  String get _currentKey => _key(_selectedDate);

  DayRecord get currentRecord {
    _records.putIfAbsent(_currentKey, () => DayRecord(dateKey: _currentKey));
    return _records[_currentKey]!;
  }

  List<DayRecord> get allRecords {
    final list = _records.values.toList();
    list.sort((a, b) => a.dateKey.compareTo(b.dateKey));
    return list;
  }

  AppProvider() { _init(); }

  Future<void> _init() async {
    await _loadLocal();
    if (SupabaseService.instance.isLoggedIn) await syncFromCloud();
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifEnabled') ?? true;
    final raw = prefs.getString('records');
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        for (final e in map.entries) {
          _records[e.key] = DayRecord.fromJson(e.value as Map<String, dynamic>);
        }
      } catch (_) {}
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('records',
        jsonEncode(_records.map((k, v) => MapEntry(k, v.toJson()))));
    await prefs.setBool('notifEnabled', _notificationsEnabled);
  }

  Future<void> syncFromCloud() async {
    if (!SupabaseService.instance.isLoggedIn) return;
    _syncing = true; notifyListeners();
    try {
      final cloud = await SupabaseService.instance.fetchMyRecords();
      for (final r in cloud) _records[r.dateKey] = r;
      await _persistLocal();
    } catch (_) {} finally {
      _syncing = false; notifyListeners();
    }
  }

  Future<void> _syncRecord(DayRecord r) async {
    if (!SupabaseService.instance.isLoggedIn) return;
    try { await SupabaseService.instance.upsertRecord(r); } catch (_) {}
  }

  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    _notificationsEnabled ? _scheduleAll() : await NotificationService.instance.cancelAll();
    await _persistLocal(); notifyListeners();
  }

  void _scheduleAll() {
    if (!_notificationsEnabled) return;
    for (final e in currentRecord.entries) {
      if (e.doseTime != null) NotificationService.instance.scheduleDoseReminder(e);
    }
  }

  void updateEntry(MealEntry updated) {
    _records.putIfAbsent(_currentKey, () => DayRecord(dateKey: _currentKey));
    final entries = _records[_currentKey]!.entries;
    final idx = entries.indexWhere((e) => e.id == updated.id);
    if (idx == -1) return;
    entries[idx] = updated;
    if (_notificationsEnabled && updated.doseTime != null)
      NotificationService.instance.scheduleDoseReminder(updated);
    _persistLocal(); _syncRecord(_records[_currentKey]!); notifyListeners();
  }

  void clearEntryData(String id) {
    final entries = _records[_currentKey]?.entries ?? [];
    final idx = entries.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    entries[idx] = entries[idx].copyWith(glycemie: null, glucides: null, dose: null, observation: null);
    _persistLocal(); _syncRecord(_records[_currentKey]!); notifyListeners();
  }

  void addSnack({required int afterIndex}) {
    _records.putIfAbsent(_currentKey, () => DayRecord(dateKey: _currentKey));
    _records[_currentKey]!.entries.insert(
        afterIndex + 1, MealEntry(name: 'Snack', type: MealType.snack));
    _persistLocal(); _syncRecord(_records[_currentKey]!); notifyListeners();
  }

  /// Ajoute une mesure capteur à une heure personnalisée (sans dose)
  void addSensorMeasure({
    required String name,
    required TimeOfDay time,
  }) {
    _records.putIfAbsent(_currentKey, () => DayRecord(dateKey: _currentKey));
    final entry = MealEntry(
      name:     name.trim().isEmpty ? 'Mesure capteur' : name.trim(),
      type:     MealType.mesure,
      mealTime: time,
      doseTime: time,
    );
    // Insérer à la bonne position chronologique
    final entries = _records[_currentKey]!.entries;
    final insertIdx = entries.indexWhere((e) {
      final t = e.mealTime ?? e.doseTime;
      if (t == null) return false;
      return (t.hour * 60 + t.minute) > (time.hour * 60 + time.minute);
    });
    if (insertIdx == -1) {
      entries.add(entry);
    } else {
      entries.insert(insertIdx, entry);
    }
    _persistLocal(); _syncRecord(_records[_currentKey]!); notifyListeners();
  }

  void removeEntry(String id) {
    _records[_currentKey]?.entries.removeWhere((e) => e.id == id);
    NotificationService.instance.cancelReminder(id);
    _persistLocal(); _syncRecord(_records[_currentKey]!); notifyListeners();
  }
}