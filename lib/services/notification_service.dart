import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/api_service.dart';
import '../data/session_store.dart';
import 'package:flutter/foundation.dart';
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
const _pushChannel = MethodChannel('reminder_app/push');

final Map<int, _PendingReminder> _pendingReminders = {};
bool _initialized = false;
String? _latestApnsToken;
const _repeatInterval = Duration(minutes: 5);
const _validityPeriod = Duration(hours: 1);
final _repeatCount = _validityPeriod.inMinutes ~/ _repeatInterval.inMinutes; // 12
const _ackActionId = 'ack_reminder';
const _ackCategory = 'reminder_ack';

int _notificationIdOf(String reminderId) => reminderId.hashCode & 0x7fffffff;
int _notificationRepeatIdOf(String reminderId, int index) =>
    ((_notificationIdOf(reminderId) + index + 1) & 0x7fffffff);

@pragma('vm:entry-point')
Future<void> onBackgroundNotificationResponse(NotificationResponse details) async {
  final id = details.id;
  if (id == null) return;
  // 后台 isolate 需要重新加载 SessionStore 以获取 auth token
  await SessionStore.load();
  final reminderId = details.payload;
  if (reminderId != null && reminderId.isNotEmpty) {
    _pendingReminders.remove(_notificationIdOf(reminderId));
    try {
      await ApiService.acknowledgeReminder(reminderId);
    } catch (e) {
      debugPrint('acknowledge error: $e');
    }
    final nid = _notificationIdOf(reminderId);
    await _notif.cancel(nid);
    for (var i = 1; i <= _repeatCount; i++) {
      await _notif.cancel(_notificationRepeatIdOf(reminderId, i));
    }
  }
}

class _PendingReminder {
  final String reminderId;
  final String title;
  final DateTime scheduledAt;
  final String userId;
  _PendingReminder(this.reminderId, this.title, this.scheduledAt, this.userId);
}

class NotificationService {
  static Future<void> registerLatestIosToken() async {
    if (!Platform.isIOS) return;
    final token = _latestApnsToken;
    if (token == null || token.isEmpty) return;
    try {
      await ApiService.registerDeviceToken(token: token, platform: 'ios');
    } catch (_) {}
  }

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
        payload: reminderId,
      );
    }
  }

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    if (Platform.isIOS) {
      _pushChannel.setMethodCallHandler((call) async {
        if (call.method == 'onApnsToken') {
          final token = (call.arguments as String?)?.trim();
          if (token != null && token.isNotEmpty) {
            _latestApnsToken = token;
            try {
              await ApiService.registerDeviceToken(token: token, platform: 'ios');
            } catch (_) {}
          }
        } else if (call.method == 'onNotificationTap') {
          final reminderId = call.arguments as String?;
          if (reminderId != null) {
            try {
              await ApiService.acknowledgeReminder(reminderId);
            } catch (_) {}
            await cancelReminder(reminderId);
          }
        }
      });
    }
    await _notif.initialize(
      InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          notificationCategories: [
            DarwinNotificationCategory(
              _ackCategory,
              actions: [
                DarwinNotificationAction.plain(_ackActionId, '我知道了',
                    options: {DarwinNotificationActionOption.foreground}),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: (details) async {
        debugPrint('notification response: actionId=${details.actionId}, payload=${details.payload}');
        final id = details.id;
        if (id == null) return;
        final pending = _pendingReminders[id];
        final reminderId = details.payload ?? pending?.reminderId;
        if (reminderId == null || reminderId.isEmpty) return;
        // "我知道了" 按钮 或 点击通知主体 → 确认并停止
        if (details.actionId == _ackActionId ||
            details.notificationResponseType == NotificationResponseType.selectedNotification) {
           try {
            await ApiService.acknowledgeReminder(reminderId);
          } catch (e) {
            debugPrint('acknowledge error: $e');
          }
          await cancelReminder(reminderId);
        } else if (pending != null) {
          // 通知触发时查询最新人数重新发送（仅在 pending 存在时）
          if (DateTime.now().difference(pending.scheduledAt) > _validityPeriod) {
            await cancelReminder(pending.reminderId);
          } else {
            int count = 0;
            try { count = await ApiService.supporterCount(pending.reminderId); } catch (_) {}
            final (body, importance, priority) = _intensity(count, pending.scheduledAt);
            final nd = _buildDetails(importance, priority);
            await _notif.show(id, pending.title, body, nd, payload: pending.reminderId);
            await _scheduleRepeats(pending.reminderId, pending.title, DateTime.now(), nd, body);
          }
        }
        await _cleanupExpired();
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
    if (Platform.isIOS) {
      try {
        await _pushChannel.invokeMethod('registerForRemoteNotifications');
      } catch (_) {}
    }
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
      } catch (_) {}
    }
    await _loadPendingReminders();
    await _cleanupExpired();
    _initialized = true;
  }

  static Future<void> scheduleReminder({
    required String reminderId,
    required String title,
    required DateTime scheduledAt,
    required String authorId,
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
    _pendingReminders[id] = _PendingReminder(reminderId, title, targetTime, authorId);
    await _savePendingReminders();

    final (body, importance, priority) = _intensity(supporterCount, targetTime);
    final details = _buildDetails(importance, priority);
    await _notif.zonedSchedule(
      id, title, body,
      tz.TZDateTime.from(targetTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminderId,
    );
    await _scheduleRepeats(reminderId, title, targetTime, details, body);
  }

  static Future<void> _cleanupExpired() async {
    final now = DateTime.now();
    final expired = _pendingReminders.entries
        .where((e) => now.difference(e.value.scheduledAt) > _validityPeriod)
        .toList();
    for (final e in expired) {
      await cancelReminder(e.value.reminderId);
    }
  }

  static Future<void> _savePendingReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _pendingReminders.map((key, value) =>
        MapEntry(key.toString(), '${value.reminderId}|${value.title}|${value.scheduledAt.millisecondsSinceEpoch}|${value.userId}'));
    await prefs.setStringList('pending_reminders', data.entries.map((e) => '${e.key}:${e.value}').toList());
  }

  static Future<void> _loadPendingReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('pending_reminders') ?? [];
    _pendingReminders.clear();
    for (final item in list) {
      final colonIdx = item.indexOf(':');
      if (colonIdx < 0) continue;
      final key = int.tryParse(item.substring(0, colonIdx));
      if (key == null) continue;
      final parts = item.substring(colonIdx + 1).split('|');
      final millis = int.tryParse(parts.length >= 3 ? parts[2] : '') ?? 0;
      final userId = parts.length >= 4 ? parts[3] : '';
      _pendingReminders[key] = _PendingReminder(parts[0], parts[1], DateTime.fromMillisecondsSinceEpoch(millis), userId);
    }
  }

  /// 清理无效通知：只保留 serverList 中存在的提醒，取消其余通知
  static Future<void> cleanupStale(List<String> validReminderIds, String userId) async {
    final validIds = validReminderIds.toSet();
    final toRemove = _pendingReminders.entries
        .where((e) => e.value.userId == userId && !validIds.contains(e.value.reminderId))
        .toList();
    for (final e in toRemove) {
      await cancelReminder(e.value.reminderId);
    }
  }

  static Future<void> reshowAllPending() async {
    final now = DateTime.now();
    for (final entry in _pendingReminders.entries.toList()) {
      final pending = entry.value;
      if (pending.scheduledAt.isAfter(now)) continue;
      int count = 0;
      try {
        count = await ApiService.supporterCount(pending.reminderId);
      } catch (_) {}
      final (body, importance, priority) = _intensity(count, pending.scheduledAt);
      final details = _buildDetails(importance, priority);
      await _notif.show(entry.key, pending.title, body, details, payload: pending.reminderId);
      await _scheduleRepeats(
        pending.reminderId,
        pending.title,
        now,
        details,
        body,
      );
    }
  }

  /// 退出登录时清理所有本地通知状态
  static Future<void> resetForLogout() async {
    for (final entry in _pendingReminders.entries.toList()) {
      final id = entry.key;
      await _notif.cancel(id);
      for (var i = 1; i <= _repeatCount; i++) {
        await _notif.cancel(_notificationRepeatIdOf(entry.value.reminderId, i));
      }
    }
    _pendingReminders.clear();
    await _savePendingReminders();
  }

  /// 重新调度所有待处理的提醒，并补充服务器上有但本地未调度的提醒
  static Future<void> rescheduleAll({
    List<({String id, String title, DateTime scheduledAt, String authorId})>? serverReminders,
  }) async {
    final now = DateTime.now();

    // 补充服务器上有但本地未调度的提醒
    if (serverReminders != null) {
      for (final r in serverReminders) {
        if (_pendingReminders.containsKey(_notificationIdOf(r.id))) continue;
        if (r.scheduledAt.isBefore(now)) continue;
        final id = _notificationIdOf(r.id);
        _pendingReminders[id] = _PendingReminder(r.id, r.title, r.scheduledAt, r.authorId);
        await _savePendingReminders();
        int count = 0;
        try { count = await ApiService.supporterCount(r.id); } catch (_) {}
        final (body, importance, priority) = _intensity(count, r.scheduledAt);
        final details = _buildDetails(importance, priority);
        await _notif.zonedSchedule(
          id, r.title, body,
          tz.TZDateTime.from(r.scheduledAt, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: r.id,
        );
        await _scheduleRepeats(r.id, r.title, r.scheduledAt, details, body);
      }
    }

    // 重新调度已有的未来提醒（恢复系统级通知）
    for (final entry in _pendingReminders.entries.toList()) {
      final pending = entry.value;
      if (pending.scheduledAt.isAfter(now)) {
        int count = 0;
        try {
          count = await ApiService.supporterCount(pending.reminderId);
        } catch (_) {}
        final (body, importance, priority) = _intensity(count, pending.scheduledAt);
        final details = _buildDetails(importance, priority);
        await _notif.zonedSchedule(
          entry.key, pending.title, body,
          tz.TZDateTime.from(pending.scheduledAt, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: pending.reminderId,
        );
        await _scheduleRepeats(pending.reminderId, pending.title, pending.scheduledAt, details, body);
      }
    }
    // 已过期的提醒立即显示
    await reshowAllPending();
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
        actions: [
          AndroidNotificationAction(
            _ackActionId,
            '我知道了',
            cancelNotification: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: iosSound,
        categoryIdentifier: _ackCategory,
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
    await _savePendingReminders();
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
