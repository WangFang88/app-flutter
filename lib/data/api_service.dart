import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_store.dart';
import 'models.dart';

class ApiService {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        if (SessionStore.token != null)
          'Authorization': 'Bearer ${SessionStore.token}',
      };

  static Future<void> loginAnonymous() async {
    final r = await http.post(
      Uri.parse('$baseUrl/auth/anonymous'),
      headers: _headers,
      body: jsonEncode({}),
    );
    final data = jsonDecode(r.body);
    await SessionStore.save(data['token'], data['user']['id'], null,
        displayLabel: data['user']['displayLabel']);
  }

    static Future<void> loginEmail(String email, String password) async {
    final r = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
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
    final r = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (r.statusCode != 200) throw Exception(jsonDecode(r.body)['error']);
    final data = jsonDecode(r.body);
    await SessionStore.save(data['token'], data['user']['id'], email,
        displayLabel: data['user']['displayLabel']);
  }

  static Future<void> bindEmail(String email, String password) async {
    final r = await http.post(
      Uri.parse('$baseUrl/auth/bind-email'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (r.statusCode != 200) throw Exception(jsonDecode(r.body)['error']);
    final data = jsonDecode(r.body);
    await SessionStore.save(data['token'], data['user']['id'], email,
        displayLabel: data['user']['displayLabel']);
  }

  static Future<List<Reminder>> getPublicReminders() async {
    final r = await http.get(Uri.parse('$baseUrl/reminders/public'), headers: _headers);
    final body = jsonDecode(r.body);
    if (body is! List) return [];
    return body.map((e) => Reminder.fromJson(e)).toList();
  }

  static Future<List<Reminder>> getMyReminders() async {
    final r = await http.get(Uri.parse('$baseUrl/reminders/mine'), headers: _headers);
    final body = jsonDecode(r.body);
    if (body is! List) return [];
    return body.map((e) => Reminder.fromJson(e)).toList();
  }

  static Future<Reminder> getReminder(String id) async {
    final r = await http.get(Uri.parse('$baseUrl/reminders/$id'), headers: _headers);
    return Reminder.fromJson(jsonDecode(r.body));
  }

  static Future<String> createReminder(String title, int scheduledAt, bool isPublic) async {
    final r = await http.post(
      Uri.parse('$baseUrl/reminders'),
      headers: _headers,
      body: jsonEncode({'title': title, 'scheduledAt': scheduledAt, 'isPublic': isPublic}),
    );
    if (r.statusCode != 200) {
      try {
        final error = jsonDecode(r.body)['error'];
        throw Exception(error ?? 'Failed to create reminder');
      } catch (_) {
        throw Exception('Failed to create reminder (${r.statusCode})');
      }
    }
    final body = jsonDecode(r.body);
    final id = body['id'];
    if (id == null) throw Exception('No id in response');
    return id as String;
  }

  static Future<void> updateReminder(String id, {String? title, int? scheduledAt, bool? isPublic}) async {
    await http.patch(
      Uri.parse('$baseUrl/reminders/$id'),
      headers: _headers,
      body: jsonEncode({
        if (title != null) 'title': title,
        if (scheduledAt != null) 'scheduledAt': scheduledAt,
        if (isPublic != null) 'isPublic': isPublic,
      }),
    );
  }

  static Future<void> deleteAllMyReminders() async {
    await http.delete(Uri.parse('$baseUrl/reminders/mine/all'), headers: _headers);
  }

  static Future<void> deleteReminder(String id) async {
    await http.delete(Uri.parse('$baseUrl/reminders/$id'), headers: _headers);
  }

  static Future<int> supporterCount(String id) async {
    final r = await http.get(Uri.parse('$baseUrl/reminders/$id/supporters/count'), headers: _headers);
    return jsonDecode(r.body)['count'] ?? 0;
  }

  static Future<bool> hasSupported(String id, String userId) async {
    final r = await http.get(Uri.parse('$baseUrl/reminders/$id/supporters/$userId/has'), headers: _headers);
    return jsonDecode(r.body)['has'] ?? false;
  }

  static Future<bool> remindOnce(String id) async {
    final r = await http.post(Uri.parse('$baseUrl/reminders/$id/remind'), headers: _headers);
    return jsonDecode(r.body)['created'] ?? false;
  }

  static Future<Map<String, dynamic>> getMyStats() async {
    final r = await http.get(Uri.parse('$baseUrl/stats/my'), headers: _headers);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  static Future<PublicStats> getPublicStats() async {
    final r = await http.get(Uri.parse('$baseUrl/stats/public'), headers: _headers);
    if (r.statusCode != 200) throw Exception('Failed to load public stats');
    return PublicStats.fromJson(jsonDecode(r.body));
  }

  static Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String environment = 'production',
  }) async {
    await http.post(
      Uri.parse('$baseUrl/devices/tokens'),
      headers: _headers,
      body: jsonEncode({
        'token': token,
        'platform': platform,
        'environment': environment,
      }),
    );
  }

  static Future<void> acknowledgeReminder(String id) async {
    await http.post(Uri.parse('$baseUrl/reminders/$id/acknowledge'), headers: _headers);
  }

  static Future<void> updateDisplayLabel(String label) async {
    final r = await http.patch(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
      body: jsonEncode({'displayLabel': label}),
    );
    if (r.statusCode != 200) throw Exception(jsonDecode(r.body)['error']);
    await SessionStore.updateDisplayLabel(label);
  }
}

