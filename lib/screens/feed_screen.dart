import 'package:flutter/material.dart';
import '../data/api_service.dart';
import '../data/models.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';

class FeedScreen extends StatefulWidget {
  final String uid;
  final void Function(String id) onOpenDetail;
  final VoidCallback onCreateNew;
  final ValueNotifier<int>? refreshNotifier;
  const FeedScreen({super.key, required this.uid, required this.onOpenDetail, required this.onCreateNew, this.refreshNotifier});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List<Reminder> _items = [];
  Map<String, int> _counts = {};
  bool _loading = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _load();
    widget.refreshNotifier?.addListener(_load);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!_initialized && mounted) setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      final items = await ApiService.getPublicReminders();
      final counts = <String, int>{};
      for (final r in items) { counts[r.id] = await ApiService.supporterCount(r.id); }
      if (mounted) setState(() { _items = items; _counts = counts; });
    } catch (_) {}
    if (mounted) setState(() { _loading = false; _initialized = true; });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(6, (_) => const SkeletonCard()),
      );
    }
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
                  Text('公共提醒', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('此刻 · ${_items.length} 个提醒', style: Theme.of(context).textTheme.bodyMedium),
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
                child: Center(child: Text('暂无公开提醒', style: TextStyle(color: Colors.grey))),
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
          heroTag: 'feed_fab',
          onPressed: widget.onCreateNew,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
    );
  }
}
