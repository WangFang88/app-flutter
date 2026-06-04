import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'data/session_store.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/mine_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/create_screen.dart';
import 'screens/stats_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 全局异常捕获：防止未处理异常导致白屏或红色错误页
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      // Release 模式下记录到控制台（后续可接入 Crashlytics）
      debugPrint('FlutterError: ${details.exception}');
    }
  };

  ErrorWidget.builder = (details) {
    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('界面加载出错', style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
              const SizedBox(height: 8),
              Text('${details.exception}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  };

  await SessionStore.load();
  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('NotificationService init failed: $e');
  }
  runApp(const ReminderApp());
}

class ReminderApp extends StatelessWidget {
  const ReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '协同提醒',
      theme: appTheme,
      darkTheme: appDarkTheme,
      themeMode: ThemeMode.system,
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = SessionStore.userId;
  }

  void _logout() => setState(() => _uid = null);

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return LoginScreen(onLoggedIn: () => setState(() => _uid = SessionStore.userId));
    }
    return MainShell(uid: _uid!, onLogout: _logout);
  }
}

class MainShell extends StatefulWidget {
  final String uid;
  final VoidCallback onLogout;
  const MainShell({super.key, required this.uid, required this.onLogout});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  List<Widget>? _screens;
  final _refreshNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    // 注册通知点击导航回调：点击通知主体 → 打开详情页
    NotificationService.registerNavigateCallback((reminderId) {
      _openDetail(reminderId);
    });
    // 处理 App 从终止状态通过点击通知启动时的待处理导航
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingId = NotificationService.consumePendingNavigation();
      if (pendingId != null) {
        _openDetail(pendingId);
      }
    });
  }

  Future<void> _openDetail(String id) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => DetailScreen(reminderId: id, myUid: widget.uid),
    ));
    if (changed == true) _refreshNotifier.value++;
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => CreateScreen(uid: widget.uid, onDone: () => Navigator.pop(context, true), onBack: () => Navigator.pop(context)),
    ));
    if (created == true) _refreshNotifier.value++;
  }

  @override
  void dispose() {
    _refreshNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _screens ??= [
      FeedScreen(uid: widget.uid, onOpenDetail: _openDetail, onCreateNew: _openCreate, refreshNotifier: _refreshNotifier),
      MineScreen(uid: widget.uid, onOpenDetail: _openDetail, onCreateNew: _openCreate, onLogout: widget.onLogout, refreshNotifier: _refreshNotifier),
      StatsScreen(refreshNotifier: _refreshNotifier),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: _screens!,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          setState(() => _tab = i);
          _refreshNotifier.value++;
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: '公开'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: '我的'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: '统计'),
        ],
      ),
    );
  }
}
