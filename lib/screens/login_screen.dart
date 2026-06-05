import 'package:flutter/material.dart';
import '../data/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _loading = true; _err = null; });
    try {
      if (_emailCtrl.text.trim().isEmpty) {
        await ApiService.loginAnonymous();
      } else {
        if (_passCtrl.text.length < 6) {
          setState(() { _err = '密码至少6位'; _loading = false; });
          return;
        }
        await ApiService.loginEmail(_emailCtrl.text.trim(), _passCtrl.text);
      }
      await NotificationService.registerLatestIosToken();
      widget.onLoggedIn();
    } catch (e) {
      setState(() { _err = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _register() async {
    setState(() { _loading = true; _err = null; });
    try {
      if (_emailCtrl.text.trim().isEmpty) {
        setState(() { _err = '请输入邮箱'; _loading = false; });
        return;
      }
      if (_passCtrl.text.length < 6) {
        setState(() { _err = '密码至少6位'; _loading = false; });
        return;
      }
      await ApiService.registerEmail(_emailCtrl.text.trim(), _passCtrl.text);
      await NotificationService.registerLatestIosToken();
      widget.onLoggedIn();
    } catch (e) {
      setState(() { _err = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? kBgDark : kSurface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.notifications_active_rounded, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text('协同提醒',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1C1C1E))),
                const SizedBox(height: 6),
                Text('公有事项可被他人叠加强度',
                    style: TextStyle(color: isDark ? const Color(0xFF8E8E93) : const Color(0xFFAEAEB2), fontSize: 14)),
                const SizedBox(height: 40),
                if (_err != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_err!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                    ]),
                  ),
                TextField(
                  controller: _emailCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: '邮箱（可选）',
                    prefixIcon: Icon(Icons.email_outlined, size: 18),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(
                    labelText: '密码（可选）',
                    prefixIcon: Icon(Icons.lock_outline, size: 18),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                GradientButton(
                  text: _emailCtrl.text.trim().isNotEmpty ? '登录' : '匿名登录',
                  onPressed: _loading ? null : _login,
                  loading: _loading,
                ),
                const SizedBox(height: 10),
                if (_emailCtrl.text.trim().isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _register,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: kPrimary.withValues(alpha: 0.4)),
                      ),
                      child: Text('注册新账号', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('不填邮箱可匿名使用',
                    style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF636366) : const Color(0xFFAEAEB2))),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}