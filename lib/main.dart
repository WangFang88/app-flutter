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

  void _openDetail(String id) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => DetailScreen(reminderId: id, myUid: widget.uid),
    ));
  }

  void _openCreate() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CreateScreen(uid: widget.uid, onDone: () => Navigator.pop(context), onBack: () => Navigator.pop(context)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    _screens ??= [
      FeedScreen(uid: widget.uid, onOpenDetail: _openDetail, onCreateNew: _openCreate),
      MineScreen(uid: widget.uid, onOpenDetail: _openDetail, onCreateNew: _openCreate, onLogout: widget.onLogout),
      const StatsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: _screens!,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: '公开'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: '我的'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: '统计'),
        ],
      ),
    );
  }
}
