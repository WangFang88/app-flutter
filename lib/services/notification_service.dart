import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../data/api_service.dart';

// 系统铃声 URI（Android 内置）
const _soundLow    = 'content://settings/system/notification_sound';   // 默认通知音
const _soundMedium = 'content://settings/system/ringtone';             // 默认来电铃声
const _soundHigh   = 'content://settings/system/alarm_alert';          // 默认闹钟铃声

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
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (details) async {
        final id = details.id;
        if (id == null) return;
        final pending = _pendingReminders[id];
        if (pending == null) return;
        if (details.notificationResponseType == NotificationResponseType.selectedNotification) {
          // 点击通知本身视为已确认
          _pendingReminders.remove(id);
        } else {
          // 通知触发时查询最新人数重新发送
          int count = 0;
          try { count = await ApiService.supporterCount(pending.reminderId); } catch (_) {}
          final (body, importance, priority) = _intensity(count, pending.scheduledAt);
          await _notif.show(id, pending.title, body, _buildDetails(importance, priority));
        }
      },
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationResponse,
    );
    final androidPlugin = _notif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    // 每种强度用独立渠道+独立声音，渠道ID含声音标识避免缓存问题
    await androidPlugin?.createNotificationChannel(AndroidNotificationChannel(
      'reminder_low_v2', '普通提醒',
      importance: Importance.defaultImportance,
      enableVibration: false,
      playSound: true,
      sound: UriAndroidNotificationSound(_soundLow),
    ));
    await androidPlugin?.createNotificationChannel(AndroidNotificationChannel(
      'reminder_medium_v2', '重要提醒',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      sound: UriAndroidNotificationSound(_soundMedium),
    ));
    await androidPlugin?.createNotificationChannel(AndroidNotificationChannel(
      'reminder_high_v2', '紧急提醒',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
      sound: UriAndroidNotificationSound(_soundHigh),
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
    final (channelId, channelName, soundUri, vibrationPattern) = importance == Importance.max
        ? ('reminder_high_v2', '紧急提醒', _soundHigh,
            Int64List.fromList([0, 300, 200, 300, 200, 300]))
        : importance == Importance.high
            ? ('reminder_medium_v2', '重要提醒', _soundMedium,
                Int64List.fromList([0, 500, 300, 500]))
            : ('reminder_low_v2', '普通提醒', _soundLow, null);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId, channelName,
        importance: importance,
        priority: priority,
        sound: UriAndroidNotificationSound(soundUri),
        enableVibration: vibrationPattern != null,
        vibrationPattern: vibrationPattern,
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
