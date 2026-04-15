import 'package:flutter/material.dart';
import '../data/api_service.dart';
import '../data/models.dart';
import '../widgets/common_widgets.dart';

class MineScreen extends StatefulWidget {
  final String uid;
  final void Function(String id) onOpenDetail;
  final VoidCallback onCreateNew;
  const MineScreen({super.key, required this.uid, required this.onOpenDetail, required this.onCreateNew});

  @override
  State<MineScreen> createState() => _MineScreenState();
}

class _MineScreenState extends State<MineScreen> {
  List<Reminder> _items = [];
  Map<String, int> _counts = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await ApiService.getMyReminders();
      final counts = <String, int>{};
      for (final r in items) {
        counts[r.id] = await ApiService.supporterCount(r.id);
      }
      if (mounted) setState(() { _items = items; _counts = counts; });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6366F1).withOpacity(0.15), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('我的提醒', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('共 ${_items.length} 个提醒', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                ]),
              ),
            ),
            if (_items.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('暂无提醒', style: TextStyle(color: Colors.grey))),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => ReminderCard(
                      reminder: _items[i],
                      supporterCount: _counts[_items[i].id] ?? 0,
                      onTap: () => widget.onOpenDetail(_items[i].id),
                    ),
                    childCount: _items.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onCreateNew,
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
