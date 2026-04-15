import 'package:flutter/material.dart';
import '../data/api_service.dart';
import '../data/models.dart';
import '../data/session_store.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';

class MineScreen extends StatefulWidget {
  final String uid;
  final void Function(String id) onOpenDetail;
  final VoidCallback onCreateNew;
  final VoidCallback onLogout;
  const MineScreen({super.key, required this.uid, required this.onOpenDetail, required this.onCreateNew, required this.onLogout});

  @override
  State<MineScreen> createState() => _MineScreenState();
}

class _MineScreenState extends State<MineScreen> {
  List<Reminder> _items = [];
  Map<String, int> _counts = {};
  bool _loading = true;
  bool _initialized = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!_initialized) setState(() => _loading = true);
    try {
      final items = await ApiService.getMyReminders();
      final counts = <String, int>{};
      for (final r in items) { counts[r.id] = await ApiService.supporterCount(r.id); }
      if (mounted) setState(() { _items = items; _counts = counts; });
    } catch (_) {}
    if (mounted) setState(() { _loading = false; _initialized = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        color: kPrimary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimary.withOpacity(0.12), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('我的提醒', style: Theme.of(context).textTheme.headlineMedium),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      onPressed: () async {
                        await SessionStore.clear();
                        widget.onLogout();
                      },
                      tooltip: '退出登录',
                    ),
                  ]),
                  Text('共 ${_items.length} 个提醒', style: Theme.of(context).textTheme.bodyMedium),
                ]),
              ),
            ),
            if (_loading)
              SliverFillRemaining(
                child: Column(children: List.generate(5, (_) => const SkeletonCard())
                    .map((e) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), child: e))
                    .toList()),
              )
            else if (_initialized && _items.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('暂无提醒', style: TextStyle(color: Colors.grey))),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx, i) => ReminderCard(
                    reminder: _items[i],
                    supporterCount: _counts[_items[i].id] ?? 0,
                    onTap: () => widget.onOpenDetail(_items[i].id),
                  ),
                  childCount: _items.length,
                )),
              ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: gradientPurple,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: FloatingActionButton(
          onPressed: widget.onCreateNew,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
    );
  }
}
