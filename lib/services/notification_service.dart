import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

const _taskName = 'reminder_notify';
const _baseUrl = 'http://192.168.124.14:8080';

final _notif = FlutterLocalNotificationsPlugin();

/// 后台任务回调（顶层函数）
@pragma('vm:entry-point')
void workmanagerCallback() {
  Workmanager().executeTask((task, inputData) async {
    if (task != _taskName) return true;
    final reminderId = inputData?['reminderId'] as String?;
    final title = inputData?['title'] as String? ?? '提醒';
    if (reminderId == null) return true;

    // 查询支持人数
    int count = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final r = await http.get(
        Uri.parse('$_baseUrl/reminders/$reminderId/supporters/count'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));
      count = jsonDecode(r.body)['count'] ?? 0;
    } catch (_) {}

    // 根据人数决定强度
    final (body, importance, priority) = _intensity(count);

    await _initNotifPlugin();
    await _notif.show(
      reminderId.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          '提醒通知',
          importance: importance,
          priority: priority,
          enableVibration: count > 0,
          playSound: true,
        ),
      ),
    );
    return true;
  });
}

(String, Importance, Priority) _intensity(int count) {
  if (count >= 5) {
    return ('$count 人和你一起提醒！快行动吧！', Importance.max, Priority.max);
  } else if (count >= 1) {
    return ('$count 人和你一起提醒', Importance.high, Priority.high);
  } else {
    return ('该提醒了', Importance.defaultImportance, Priority.defaultPriority);
  }
}

Future<void> _initNotifPlugin() async {
  await _notif.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
}

class NotificationService {
  static Future<void> init() async {
    tz_data.initializeTimeZones();
    await _initNotifPlugin();
    await Workmanager().initialize(workmanagerCallback);
  }

  /// 调度一个提醒：在 scheduledAt 时刻触发后台任务查询人数并发通知
  static Future<void> scheduleReminder({
    required String reminderId,
    required String title,
    required DateTime scheduledAt,
  }) async {
    final delay = scheduledAt.difference(DateTime.now());
    if (delay.isNegative) return;

    await Workmanager().registerOneOffTask(
      reminderId,
      _taskName,
      initialDelay: delay,
      inputData: {'reminderId': reminderId, 'title': title},
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  static Future<void> cancelReminder(String reminderId) async {
    await Workmanager().cancelByUniqueName(reminderId);
  }
}
