import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

final _notif = FlutterLocalNotificationsPlugin();

class NotificationService {
  static Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    await _notif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _notif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleReminder({
    required String reminderId,
    required String title,
    required DateTime scheduledAt,
    int supporterCount = 0,
  }) async {
    final delay = scheduledAt.difference(DateTime.now());
    if (delay.isNegative) return;

    final (body, importance, priority) = _intensity(supporterCount);

    await _notif.zonedSchedule(
      reminderId.hashCode,
      title,
      body,
      tz.TZDateTime.from(scheduledAt, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          '提醒通知',
          importance: importance,
          priority: priority,
          enableVibration: supporterCount > 0,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder(String reminderId) async {
    await _notif.cancel(reminderId.hashCode);
  }

  static (String, Importance, Priority) _intensity(int count) {
    if (count >= 5) {
      return ('$count 人和你一起提醒！快行动吧！', Importance.max, Priority.max);
    } else if (count >= 1) {
      return ('$count 人和你一起提醒', Importance.high, Priority.high);
    }
    return ('该提醒了', Importance.defaultImportance, Priority.defaultPriority);
  }
}
