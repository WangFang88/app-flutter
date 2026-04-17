import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_store.dart';
import 'models.dart';

class ApiService {
  static const baseUrl = 'http://192.168.124.14:8080';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
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
    await SessionStore.save(data['token'], data['user']['id'], null);
  }

  static Future<void> loginEmail(String email, String password) async {
    http.Response r;
    try {
      r = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (r.statusCode == 404) {
        r = await http.post(
          Uri.parse('$baseUrl/auth/register'),
          headers: _headers,
          body: jsonEncode({'email': email, 'password': password}),
        );
      }
    } catch (e) {
      rethrow;
    }
    if (r.statusCode != 200) throw Exception(jsonDecode(r.body)['error']);
    final data = jsonDecode(r.body);
    await SessionStore.save(data['token'], data['user']['id'], email);
  }

  static Future<List<Reminder>> getPublicReminders() async {
    final r = await http.get(Uri.parse('$baseUrl/reminders/public'), headers: _headers);
    return (jsonDecode(r.body) as List).map((e) => Reminder.fromJson(e)).toList();
  }

  static Future<List<Reminder>> getMyReminders() async {
    final r = await http.get(Uri.parse('$baseUrl/reminders/mine'), headers: _headers);
    return (jsonDecode(r.body) as List).map((e) => Reminder.fromJson(e)).toList();
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
    return jsonDecode(r.body)['id'];
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
}
