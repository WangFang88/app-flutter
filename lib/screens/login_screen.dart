import 'package:flutter/material.dart';
import '../data/api_service.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;
  const LoginScreen({super.key, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _err;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A1730), const Color(0xFF13111E)]
                : [const Color(0xFF6366F1), const Color(0xFF8B5CF6), const Color(0xFFF8F7FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: isDark ? [0, 1] : [0, 0.35, 0.7],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Logo区域
                  Center(
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        gradient: gradientPurple,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      child: const Icon(Icons.notifications_active_rounded, size: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(child: Text('协同提醒',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.white))),
                  const SizedBox(height: 8),
                  Center(child: Text('公有事项可被他人「提醒他」叠加强度',
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.white70, fontSize: 14))),
                  const SizedBox(height: 52),
                  // 表单卡片
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? kCardDark : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))],
                    ),
                    child: Column(children: [
                      if (_err != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
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
                        text: _emailCtrl.text.trim().isNotEmpty ? '邮箱登录 / 注册' : '匿名登录',
                        onPressed: _loading ? null : _login,
                        loading: _loading,
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
