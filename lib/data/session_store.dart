import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _keyToken = 'token';
  static const _keyUserId = 'userId';
  static const _keyEmail = 'email';
  static const _keyDisplayLabel = 'displayLabel';

  static String? _token;
  static String? _userId;
  static String? _email;
  static String? _displayLabel;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _token = p.getString(_keyToken);
    _userId = p.getString(_keyUserId);
    _email = p.getString(_keyEmail);
    _displayLabel = p.getString(_keyDisplayLabel);
  }

  static Future<void> save(String token, String userId, String? email, {String? displayLabel}) async {
    _token = token;
    _userId = userId;
    _email = email;
    if (displayLabel != null) _displayLabel = displayLabel;
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyToken, token);
    await p.setString(_keyUserId, userId);
    if (email != null) await p.setString(_keyEmail, email);
    if (displayLabel != null) await p.setString(_keyDisplayLabel, displayLabel);
  }

  static Future<void> clear() async {
    _token = null;
    _userId = null;
    _email = null;
    _displayLabel = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyToken);
    await p.remove(_keyUserId);
    await p.remove(_keyEmail);
    await p.remove(_keyDisplayLabel);
  }

  static Future<void> updateEmail(String email) async {
    _email = email;
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyEmail, email);
  }

  static Future<void> updateDisplayLabel(String label) async {
    _displayLabel = label;
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyDisplayLabel, label);
  }

  static String? get token => _token;
  static String? get userId => _userId;
  static String? get email => _email;
  static String? get displayLabel => _displayLabel;
}
