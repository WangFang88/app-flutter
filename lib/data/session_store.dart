import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _keyToken = 'token';
  static const _keyUserId = 'userId';
  static const _keyEmail = 'email';

  static String? _token;
  static String? _userId;
  static String? _email;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _token = p.getString(_keyToken);
    _userId = p.getString(_keyUserId);
    _email = p.getString(_keyEmail);
  }

  static Future<void> save(String token, String userId, String? email) async {
    _token = token;
    _userId = userId;
    _email = email;
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyToken, token);
    await p.setString(_keyUserId, userId);
    if (email != null) await p.setString(_keyEmail, email);
  }

  static Future<void> clear() async {
    _token = null;
    _userId = null;
    _email = null;
    final p = await SharedPreferences.getInstance();
    await p.clear();
  }

  static String? get token => _token;
  static String? get userId => _userId;
  static String? get email => _email;
}
