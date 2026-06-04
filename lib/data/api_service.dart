import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_store.dart';
import 'models.dart';

class ApiService {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dangling-mumbling-arson.ngrok-free.dev',
  );

  static const _timeout = Duration(seconds: 15);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (SessionStore.token != null)
          'Authorization': 'Bearer ${SessionStore.token}',
      };

  /// 统一的 HTTP 请求包装，自动加超时和错误处理
  static Future<http.Response> _get(Uri url) =>
      http.get(url, headers: _headers).timeout(_timeout);

  static Future<http.Response> _post(Uri url, {Object? body}) =>
      http.post(url, headers: _headers, body: body).timeout(_timeout);

  static Future<http.Response> _patch(Uri url, {Object? body}) =>
      http.patch(url, headers: _headers, body: body).timeout(_timeout);

  static Future<http.Response> _delete(Uri url) =>
      http.delete(url, headers: _headers).timeout(_timeout);

  static Future<void> loginAnonymous() async {
    final r = await _post(
      Uri.parse('$baseUrl/auth/anonymous'),
      body: jsonEncode({}),
    );
    if (r.statusCode != 200) throw Exception('匿名登录失败 (${r.statusCode})');
    final data = jsonDecode(r.body);
    await SessionStore.save(data['token'], data['user']['id'], null,
        displayLabel: data['user']['displayLabel']);
  }

  static Future<void> loginEmail(String email, String password) async {
    final r = await _post(
      Uri.parse('$baseUrl/auth/login'),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (r.statusCode == 404) throw Exception('该邮箱未注册，请先注册');
    if (r.statusCode == 401) throw Exception('密码错误');
    if (r.statusCode != 200) throw Exception(jsonDecode(r.body)['error']);
    final data = jsonDecode(r.body);
    await SessionStore.save(data['token'], data['user']['id'], email,
        displayLabel: data['user']['displayLabel']);
  }

  static Future<void> registerEmail(String email, String password) async {
    final r = await _post(
      Uri.parse('$baseUrl/auth/register'),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (r.statusCode != 200) throw Exception(jsonDecode(r.body)['error']);
    final data = jsonDecode(r.body);
    await SessionStore.save(data['token'], data['user']['id'], email,
        displayLabel: data['user']['displayLabel']);
  }

  static Future<void> bindEmail(String email, String password) async {
    final r = await _post(
      Uri.parse('$baseUrl/auth/bind-email'),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (r.statusCode != 200) throw Exception(jsonDecode(r.body)['error']);
    final data = jsonDecode(r.body);
    await SessionStore.save(data['token'], data['user']['id'], email,
        displayLabel: data['user']['displayLabel']);
  }

  static Future<List<Reminder>> getPublicReminders() async {
    final r = await _get(Uri.parse('$baseUrl/reminders/public'));
    if (r.statusCode != 200) throw Exception('加载公开提醒失败');
    final body = jsonDecode(r.body);
    if (body is! List) return [];
    return body.map((e) => Reminder.fromJson(e)).toList();
  }

  static Future<List<Reminder>> getMyReminders() async {
    final r = await _get(Uri.parse('$baseUrl/reminders/mine'));
    if (r.statusCode != 200) throw Exception('加载我的提醒失败');
    final body = jsonDecode(r.body);
    if (body is! List) return [];
    return body.map((e) => Reminder.fromJson(e)).toList();
  }

  static Future<Reminder> getReminder(String id) async {
    final r = await _get(Uri.parse('$baseUrl/reminders/$id'));
    if (r.statusCode != 200) throw Exception('加载提醒详情失败');
    return Reminder.fromJson(jsonDecode(r.body));
  }

  static Future<String> createReminder(String title, int scheduledAt, bool isPublic) async {
    final r = await _post(
      Uri.parse('$baseUrl/reminders'),
      body: jsonEncode({'title': title, 'scheduledAt': scheduledAt, 'isPublic': isPublic}),
    );
    if (r.statusCode != 200) {
      try {
        final error = jsonDecode(r.body)['error'];
        throw Exception(error ?? '创建提醒失败');
      } catch (e) {
        if (e is Exception && e.toString().contains('Exception:')) rethrow;
        throw Exception('创建提醒失败 (${r.statusCode})');
      }
    }
    final body = jsonDecode(r.body);
    final id = body['id'];
    if (id == null) throw Exception('服务器未返回 ID');
    return id as String;
  }

  static Future<void> updateReminder(String id, {String? title, int? scheduledAt, bool? isPublic}) async {
    final r = await _patch(
      Uri.parse('$baseUrl/reminders/$id'),
      body: jsonEncode({
        if (title != null) 'title': title,
        if (scheduledAt != null) 'scheduledAt': scheduledAt,
        if (isPublic != null) 'isPublic': isPublic,
      }),
    );
    if (r.statusCode != 200) throw Exception('更新提醒失败');
  }

  static Future<void> deleteAllMyReminders() async {
    final r = await _delete(Uri.parse('$baseUrl/reminders/mine/all'));
    if (r.statusCode != 200) throw Exception('清空提醒失败');
  }

  static Future<void> deleteReminder(String id) async {
    final r = await _delete(Uri.parse('$baseUrl/reminders/$id'));
    if (r.statusCode != 200) throw Exception('删除提醒失败');
  }

  static Future<int> supporterCount(String id) async {
    final r = await _get(Uri.parse('$baseUrl/reminders/$id/supporters/count'));
    if (r.statusCode != 200) return 0;
    return jsonDecode(r.body)['count'] ?? 0;
  }

  static Future<bool> hasSupported(String id, String userId) async {
    final r = await _get(Uri.parse('$baseUrl/reminders/$id/supporters/$userId/has'));
    if (r.statusCode != 200) return false;
    return jsonDecode(r.body)['has'] ?? false;
  }

  static Future<bool> remindOnce(String id) async {
    final r = await _post(Uri.parse('$baseUrl/reminders/$id/remind'));
    if (r.statusCode != 200) throw Exception('提醒失败');
    return jsonDecode(r.body)['created'] ?? false;
  }

  static Future<Map<String, dynamic>> getMyStats() async {
    final r = await _get(Uri.parse('$baseUrl/stats/my'));
    if (r.statusCode != 200) throw Exception('加载统计失败');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  static Future<PublicStats> getPublicStats() async {
    final r = await _get(Uri.parse('$baseUrl/stats/public'));
    if (r.statusCode != 200) throw Exception('加载公开统计失败');
    return PublicStats.fromJson(jsonDecode(r.body));
  }

  static Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String environment = 'production',
  }) async {
    await _post(
      Uri.parse('$baseUrl/devices/tokens'),
      body: jsonEncode({
        'token': token,
        'platform': platform,
        'environment': environment,
      }),
    );
  }

  static Future<void> acknowledgeReminder(String id) async {
    final r = await _post(Uri.parse('$baseUrl/reminders/$id/acknowledge'));
    if (r.statusCode != 200) {
      throw Exception('确认失败: ${r.statusCode}');
    }
  }

  static Future<void> updateDisplayLabel(String label) async {
    final r = await _patch(
      Uri.parse('$baseUrl/users/me'),
      body: jsonEncode({'displayLabel': label}),
    );
    if (r.statusCode != 200) throw Exception(jsonDecode(r.body)['error']);
    await SessionStore.updateDisplayLabel(label);
  }
}

