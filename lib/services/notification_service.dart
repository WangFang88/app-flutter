import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../data/api_service.dart';

final _notif = FlutterLocalNotificationsPlugin();
const _channel = MethodChannel('reminder_app/battery');

final Map<int, _PendingReminder> _pendingReminders = {};

@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse details) {
  _pendingReminders.remove(details.id);
}

class _PendingReminder {
  final String reminderId;
  final String title;
  final DateTime scheduledAt;
  _PendingReminder(this.reminderId, this.title, this.scheduledAt);
}

class NotificationService {
  static Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    await _notif.initialize(
      InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (details) {
        // 点击通知本身即视为已确认，停止重复
        _pendingReminders.remove(details.id);
      },
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationResponse,
    );
    await _notif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'reminder_high_channel',
          '提醒通知',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        ));
    await _notif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
      } catch (_) {}
    }
  }

  static Future<void> scheduleReminder({
    required String reminderId,
    required String title,
    required DateTime scheduledAt,
    int supporterCount = 0,
  }) async {
    final delay = scheduledAt.difference(DateTime.now());
    if (delay.isNegative) return;

    final id = reminderId.hashCode;
    _pendingReminders[id] = _PendingReminder(reminderId, title, scheduledAt);

    final (body, importance, priority) = _intensity(supporterCount, scheduledAt);
    await _notif.zonedSchedule(
      id, title, body,
      tz.TZDateTime.from(scheduledAt, tz.local),
      _buildDetails(importance, priority),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> reshowAllPending() async {
    for (final entry in _pendingReminders.entries.toList()) {
      final pending = entry.value;
      int count = 0;
      try {
        count = await ApiService.supporterCount(pending.reminderId);
      } catch (_) {}
      final (body, importance, priority) = _intensity(count, pending.scheduledAt);
      await _notif.show(entry.key, pending.title, body, _buildDetails(importance, priority));
    }
  }

  static NotificationDetails _buildDetails(Importance importance, Priority priority) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'reminder_high_channel',
        '提醒通知',
        importance: importance,
        priority: priority,
        enableVibration: true,
        autoCancel: true,
      ),
    );
  }

  static Future<void> cancelReminder(String reminderId) async {
    final id = reminderId.hashCode;
    _pendingReminders.remove(id);
    await _notif.cancel(id);
  }

  static (String, Importance, Priority) _intensity(int count, DateTime scheduledAt) {
    final timeStr = '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
    if (count >= 5) {
      return ('$timeStr 提醒时间到！$count 人和你一起！', Importance.max, Priority.max);
    } else if (count >= 1) {
      return ('$timeStr 提醒时间到！$count 人和你一起', Importance.high, Priority.high);
    }
    return ('$timeStr 提醒时间到！', Importance.defaultImportance, Priority.defaultPriority);
  }
}
