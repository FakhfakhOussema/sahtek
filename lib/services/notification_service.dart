import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/meal_entry.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'sahtek_doses';
  static const _channelName = 'Rappels de doses';
  static const _channelDesc = 'Notification 5 min avant la prise de dose';

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );

    // Request Android 13+ permission
    final androidPlugin =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> scheduleDoseReminder(MealEntry entry) async {
    if (entry.doseTime == null) return;

    final now = DateTime.now();
    var scheduled = DateTime(
      now.year, now.month, now.day,
      entry.doseTime!.hour,
      entry.doseTime!.minute,
    ).subtract(const Duration(minutes: 5));

    // Si l'heure est déjà passée aujourd'hui, programmer pour demain
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      entry.id.hashCode & 0x7FFFFFFF,
      '💉 Sahtek – Rappel dose',
      'Prenez votre dose pour ${entry.name} dans 5 minutes',
      tz.TZDateTime.from(scheduled, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder(String entryId) async {
    await _plugin.cancel(entryId.hashCode & 0x7FFFFFFF);
  }

  Future<void> cancelAll() async => _plugin.cancelAll();
}