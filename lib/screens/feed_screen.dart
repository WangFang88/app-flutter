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
  bool _loadFailed = false;

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
      if (mounted) setState(() { _items = items; _counts = counts; _loadFailed = false; });
    } catch (e) {
      if (mounted && _items.isEmpty) {
        setState(() => _loadFailed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('公共提醒', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('${_items.length} 个提醒', style: Theme.of(context).textTheme.bodyMedium),
                ]),
              ),
            ),
            if (_loading)
              SliverFillRemaining(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(children: List.generate(5, (_) => const SkeletonCard())),
                ),
              )
            else if (_initialized && _items.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('暂无公开提醒', style: TextStyle(color: Color(0xFFAEAEB2)))),
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'feed_fab',
        onPressed: widget.onCreateNew,
        backgroundColor: kPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}