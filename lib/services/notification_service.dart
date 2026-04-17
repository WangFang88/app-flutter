import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

final _notif = FlutterLocalNotificationsPlugin();
const _channel = MethodChannel('reminder_app/battery');

// 存储待重复的通知信息
final Map<int, _PendingReminder> _pendingReminders = {};

@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse details) {
  if (details.actionId == 'confirm') {
    _pendingReminders.remove(details.id);
  }
}

class _PendingReminder {
  final String title;
  final String body;
  final Importance importance;
  final Priority priority;
  _PendingReminder(this.title, this.body, this.importance, this.priority);
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
        if (details.actionId == 'confirm') {
          _pendingReminders.remove(details.id);
          _notif.cancel(details.id!);
        }
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

    final (body, importance, priority) = _intensity(supporterCount, scheduledAt);
    final id = reminderId.hashCode;
    _pendingReminders[id] = _PendingReminder(title, body, importance, priority);

    await _notif.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledAt, tz.local),
      _buildDetails(importance, priority),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 重新发送通知（用于重复提醒）
  static Future<void> reshowIfPending(int id) async {
    final pending = _pendingReminders[id];
    if (pending == null) return;
    await _notif.show(id, pending.title, pending.body, _buildDetails(pending.importance, pending.priority));
  }

  static Future<void> reshowAllPending() async {
    for (final id in _pendingReminders.keys.toList()) {
      await reshowIfPending(id);
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
        ongoing: true,
        autoCancel: false,
        actions: const [
          AndroidNotificationAction('confirm', '确定', cancelNotification: true),
        ],
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
