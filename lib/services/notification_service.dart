import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

final _notif = FlutterLocalNotificationsPlugin();
const _channel = MethodChannel('reminder_app/battery');

class NotificationService {
  static Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    await _notif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    // 创建高优先级通知渠道
    await _notif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'reminder_high_channel',
          '提醒通知',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
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

    await _notif.zonedSchedule(
      reminderId.hashCode,
      title,
      body,
      tz.TZDateTime.from(scheduledAt, tz.local),
      NotificationDetails(
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
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder(String reminderId) async {
    await _notif.cancel(reminderId.hashCode);
  }

  /// 立即发一条测试通知，用于验证权限是否正常
  static Future<void> showTestNotification() async {
    await _notif.show(
      0,
      '通知测试',
      '通知功能正常！',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_high_channel',
          '提醒通知',
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
    );
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
