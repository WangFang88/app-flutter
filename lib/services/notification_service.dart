import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../data/api_service.dart';

// Android 自定义声音（放在 android/app/src/main/res/raw/）
const _soundLow = RawResourceAndroidNotificationSound('reminder_low');
const _soundMedium = RawResourceAndroidNotificationSound('reminder_medium');
const _soundHigh = RawResourceAndroidNotificationSound('reminder_high');

// iOS 自定义声音（放在 ios/Runner，并加入 Copy Bundle Resources）
const _iosSoundLow = 'reminder_low.caf';
const _iosSoundMedium = 'reminder_medium.caf';
const _iosSoundHigh = 'reminder_high.caf';

final _notif = FlutterLocalNotificationsPlugin();
const _channel = MethodChannel('reminder_app/battery');

final Map<int, _PendingReminder> _pendingReminders = {};
bool _initialized = false;
const _repeatInterval = Duration(minutes: 2);
const _repeatCount = 30;

int _notificationIdOf(String reminderId) => reminderId.hashCode & 0x7fffffff;
int _notificationRepeatIdOf(String reminderId, int index) =>
    ((_notificationIdOf(reminderId) + index + 1) & 0x7fffffff);

@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse details) {
  final id = details.id;
  if (id == null) return;
  _pendingReminders.remove(id);
}

class _PendingReminder {
  final String reminderId;
  final String title;
  final DateTime scheduledAt;
  _PendingReminder(this.reminderId, this.title, this.scheduledAt);
}

class NotificationService {
  static Future<void> _scheduleRepeats(
    String reminderId,
    String title,
    DateTime fromTime,
    NotificationDetails details,
    String body,
  ) async {
    for (var i = 1; i <= _repeatCount; i++) {
      final repeatId = _notificationRepeatIdOf(reminderId, i);
      await _notif.cancel(repeatId);
      await _notif.zonedSchedule(
        repeatId,
        title,
        body,
        tz.TZDateTime.from(fromTime.add(_repeatInterval * i), tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> init() async {
    if (_initialized) return;
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
          await cancelReminder(pending.reminderId);
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
      'reminder_low_v3', '普通提醒',
      importance: Importance.defaultImportance,
      enableVibration: false,
      playSound: true,
      sound: _soundLow,
    ));
    await androidPlugin?.createNotificationChannel(AndroidNotificationChannel(
      'reminder_medium_v3', '重要提醒',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      sound: _soundMedium,
    ));
    await androidPlugin?.createNotificationChannel(AndroidNotificationChannel(
      'reminder_high_v3', '紧急提醒',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
      sound: _soundHigh,
    ));
    await _notif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
    await _notif
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
      } catch (_) {}
    }
    _initialized = true;
  }

  static Future<void> scheduleReminder({
    required String reminderId,
    required String title,
    required DateTime scheduledAt,
    int supporterCount = 0,
  }) async {
    if (!_initialized) {
      await init();
    }
    final now = DateTime.now();
    final delay = scheduledAt.difference(now);
    if (delay.isNegative) return;
    final targetTime = delay < const Duration(seconds: 5)
        ? now.add(const Duration(seconds: 5))
        : scheduledAt;

    final id = _notificationIdOf(reminderId);
    _pendingReminders[id] = _PendingReminder(reminderId, title, targetTime);

    final (body, importance, priority) = _intensity(supporterCount, targetTime);
    final details = _buildDetails(importance, priority);
    await _notif.zonedSchedule(
      id, title, body,
      tz.TZDateTime.from(targetTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    await _scheduleRepeats(reminderId, title, targetTime, details, body);
  }

  static Future<void> reshowAllPending() async {
    for (final entry in _pendingReminders.entries.toList()) {
      final pending = entry.value;
      int count = 0;
      try {
        count = await ApiService.supporterCount(pending.reminderId);
      } catch (_) {}
      final (body, importance, priority) = _intensity(count, pending.scheduledAt);
      final details = _buildDetails(importance, priority);
      await _notif.show(entry.key, pending.title, body, details);
      await _scheduleRepeats(
        pending.reminderId,
        pending.title,
        DateTime.now(),
        details,
        body,
      );
    }
  }

  static NotificationDetails _buildDetails(Importance importance, Priority priority) {
    final (channelId, channelName, sound, iosSound, vibrationPattern) = importance == Importance.max
        ? ('reminder_high_v3', '紧急提醒', _soundHigh, _iosSoundHigh,
            Int64List.fromList([0, 300, 200, 300, 200, 300]))
        : importance == Importance.high
            ? ('reminder_medium_v3', '重要提醒', _soundMedium, _iosSoundMedium,
                Int64List.fromList([0, 500, 300, 500]))
            : ('reminder_low_v3', '普通提醒', _soundLow, _iosSoundLow, null);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId, channelName,
        importance: importance,
        priority: priority,
        sound: sound,
        enableVibration: vibrationPattern != null,
        vibrationPattern: vibrationPattern,
        autoCancel: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: iosSound,
      ),
    );
  }

  static Future<void> cancelReminder(String reminderId) async {
    final id = _notificationIdOf(reminderId);
    _pendingReminders.remove(id);
    await _notif.cancel(id);
    for (var i = 1; i <= _repeatCount; i++) {
      await _notif.cancel(_notificationRepeatIdOf(reminderId, i));
    }
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
