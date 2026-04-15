import 'package:flutter/material.dart';
import 'data/session_store.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/mine_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/create_screen.dart';
import 'screens/stats_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionStore.load();
  runApp(const ReminderApp());
}

class ReminderApp extends StatelessWidget {
  const ReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '协同提醒',
      theme: appTheme,
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

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return LoginScreen(onLoggedIn: () => setState(() => _uid = SessionStore.userId));
    }
    return MainShell(uid: _uid!);
  }
}

class MainShell extends StatefulWidget {
  final String uid;
  const MainShell({super.key, required this.uid});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  void _openDetail(BuildContext context, String id) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => DetailScreen(reminderId: id, myUid: widget.uid),
    ));
  }

  void _openCreate(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CreateScreen(uid: widget.uid, onDone: () => Navigator.pop(context), onBack: () => Navigator.pop(context)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      FeedScreen(uid: widget.uid, onOpenDetail: (id) => _openDetail(context, id), onCreateNew: () => _openCreate(context)),
      MineScreen(uid: widget.uid, onOpenDetail: (id) => _openDetail(context, id), onCreateNew: () => _openCreate(context)),
      const StatsScreen(),
    ];

    return Scaffold(
      body: screens[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '公开'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: '统计'),
        ],
      ),
    );
  }
}
