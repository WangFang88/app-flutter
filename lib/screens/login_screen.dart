import 'package:flutter/material.dart';
import '../data/api_service.dart';
import '../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;
  const LoginScreen({super.key, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _err;

  Future<void> _login() async {
    setState(() { _loading = true; _err = null; });
    try {
      if (_emailCtrl.text.isBlank) {
        await ApiService.loginAnonymous();
      } else {
        if (_passCtrl.text.length < 6) {
          setState(() { _err = '密码至少6位'; _loading = false; });
          return;
        }
        await ApiService.loginEmail(_emailCtrl.text.trim(), _passCtrl.text);
      }
      widget.onLoggedIn();
    } catch (e) {
      setState(() { _err = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.3, 0.7],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.notifications_active, size: 72, color: Colors.white),
                const SizedBox(height: 16),
                const Text('协同提醒',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('公有事项可被他人「提醒他」叠加强度',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 48),
                if (_err != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_err!, style: const TextStyle(color: Colors.red)),
                  ),
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: '邮箱（可选）',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(
                    labelText: '密码（可选）',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                GradientButton(
                  text: _emailCtrl.text.isNotEmpty ? '邮箱登录 / 注册' : '匿名登录',
                  onPressed: _loading ? null : _login,
                  loading: _loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on String {
  bool get isBlank => trim().isEmpty;
  bool get isNotEmpty => trim().isNotEmpty;
}
