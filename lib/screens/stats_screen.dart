import 'package:flutter/material.dart';
import '../data/api_service.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import 'who_reminded_screen.dart';

class StatsScreen extends StatefulWidget {
  final ValueNotifier<int>? refreshNotifier;
  const StatsScreen({super.key, this.refreshNotifier});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  int _published = 0;
  int _totalClicks = 0;
  List<int> _hourlyData = List.filled(24, 0);
  List<Map<String, dynamic>> _whoRemindedRaw = [];

  PublicStats? _publicStats;
  bool _publicStatsLoading = true;
  String? _publicStatsError;
  int _portraitDimension = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadPublicStats();
    widget.refreshNotifier?.addListener(_load);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_load);
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([_load(), _loadPublicStats()]);
  }

  Future<void> _loadPublicStats() async {
    setState(() { _publicStatsLoading = true; _publicStatsError = null; });
    try {
      final stats = await ApiService.getPublicStats();
      if (mounted) setState(() { _publicStats = stats; _publicStatsLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _publicStatsError = '加载失败'; _publicStatsLoading = false; });
    }
  }

  Future<void> _load() async {
    try {
      final stats = await ApiService.getMyStats();
      if (mounted) setState(() {
        _published = stats['publishedWithReminds'] ?? 0;
        _totalClicks = stats['totalRemindClicks'] ?? 0;
        _whoRemindedRaw = (stats['whoReminded'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ?? [];
        final scheduledAts = stats['scheduledAts'] as List<dynamic>?;
        if (scheduledAts != null) {
          _hourlyData = List.filled(24, 0);
          for (final ts in scheduledAts) {
            final hour = DateTime.fromMillisecondsSinceEpoch((ts as num).toInt()).hour;
            _hourlyData[hour]++;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载统计失败: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: kPrimary,
          onRefresh: _refreshAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('统计', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('数据概览', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: _MetricCard(label: '被提醒事项', value: '$_published', icon: Icons.task_alt_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _MetricCard(
                label: '提醒总人次',
                value: '$_totalClicks',
                icon: Icons.people_rounded,
                onTap: _whoRemindedRaw.isEmpty ? null : () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => WhoRemindedScreen(events: _whoRemindedRaw),
                  ));
                },
              )),
            ]),
            const SizedBox(height: 28),
            if (_publicStatsLoading)
              const _TimePortraitSkeleton()
            else if (_publicStatsError != null)
              _TimePortraitError(message: _publicStatsError!, onRetry: _loadPublicStats)
            else if (_publicStats != null)
              _TimePortraitSection(
                isDark: isDark,
                data: _publicStats!,
                selectedDimension: _portraitDimension,
                onDimensionChanged: (v) => setState(() => _portraitDimension = v),
              ),
            const SizedBox(height: 28),
            Text('每小时活跃', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _BarChart(isDark: isDark, data: _hourlyData),
          ]),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  const _MetricCard({required this.label, required this.value, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? kCardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(gradient: gradientPurple, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kPrimary)),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]),
    ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final bool isDark;
  final List<int> data;
  const _BarChart({required this.isDark, required this.data});
  static const double barWidth = 28;

  @override
  Widget build(BuildContext context) {
    // 显示全部24小时
    final slots = List.generate(24, (i) => i);
    final values = slots.map((h) => data.length > h ? data[h] : 0).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b).toDouble();
    final labels = slots.map((h) => '${h}时').toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? kCardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: barWidth * 24, // 24根柱子的总宽度
        child: Column(children: [
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(values.length, (i) => SizedBox(
              width: barWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (values[i] > 0)
                    Text('${values[i]}', style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey)),
                  const SizedBox(height: 4),
                  Container(
                    height: maxVal > 0 ? 100 * values[i] / maxVal : 4,
                    decoration: BoxDecoration(
                      gradient: gradientPurple,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 3))],
                    ),
                  ),
                ]),
              ),
            )),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: List.generate(labels.length, (i) => Expanded(
          child: Center(child: Text(labels[i],
              style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey))),
        ))),
        ]),
      ),
    ),
  );}
}

class _TimePortraitSection extends StatelessWidget {
  final bool isDark;
  final PublicStats data;
  final int selectedDimension;
  final ValueChanged<int> onDimensionChanged;
  const _TimePortraitSection({
    required this.isDark,
    required this.data,
    required this.selectedDimension,
    required this.onDimensionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hourlyData = selectedDimension == 0 ? data.hourlyByItem : data.hourlyByRemind;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? kCardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('时间画像', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text('全平台', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kPrimary)),
          ),
        ]),
        const SizedBox(height: 12),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('按事项数量')),
            ButtonSegment(value: 1, label: Text('按被提醒总次数')),
          ],
          selected: {selectedDimension},
          onSelectionChanged: (set) => onDimensionChanged(set.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 16),
        _BarChart(isDark: isDark, data: hourlyData),
        const SizedBox(height: 12),
        _Top3Summary(isDark: isDark, hourlyData: hourlyData, isByItem: selectedDimension == 0),
      ]),
    );
  }
}

class _Top3Summary extends StatelessWidget {
  final bool isDark;
  final List<int> hourlyData;
  final bool isByItem;
  const _Top3Summary({required this.isDark, required this.hourlyData, required this.isByItem});

  @override
  Widget build(BuildContext context) {
    final entries = List.generate(24, (i) => MapEntry(i, hourlyData[i]));
    entries.sort((a, b) => b.value.compareTo(a.value));
    final top3 = entries.where((e) => e.value > 0).take(3).toList();

    if (top3.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('暂无数据', style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey)),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < top3.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            _RankBadge(rank: i + 1),
            const SizedBox(width: 10),
            Text(
              '${top3[i].key}:00-${top3[i].key + 1}:00',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1730),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              i == 0 ? '最热门' : '第${i + 1}热门',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey),
            ),
            const Spacer(),
            Text(
              '${top3[i].value}${isByItem ? "项" : "次"}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kPrimary),
            ),
          ]),
        ),
    ]);
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: rank == 1 ? gradientPurple : null,
        color: rank == 1 ? null : kPrimary.withOpacity(0.15 + 0.05 * rank),
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: rank == 1 ? Colors.white : kPrimary,
        ),
      ),
    );
  }
}

class _TimePortraitSkeleton extends StatelessWidget {
  const _TimePortraitSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white12 : Colors.grey.shade200;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? kCardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 120, height: 18, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(8))),
        const SizedBox(height: 12),
        Container(width: double.infinity, height: 36, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(10))),
        const SizedBox(height: 16),
        Row(
          children: List.generate(12, (i) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(
                  height: 40 + (i * 7 % 60).toDouble(),
                  decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(6)),
                ),
                const SizedBox(height: 6),
                Container(width: 16, height: 8, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4))),
              ]),
            ),
          )),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: baseColor)),
              const SizedBox(width: 10),
              Container(width: 100, height: 14, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(6))),
              const Spacer(),
              Container(width: 36, height: 14, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(6))),
            ]),
          ),
      ]),
    );
  }
}

class _TimePortraitError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _TimePortraitError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? kCardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Text('时间画像', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text('全平台', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kPrimary)),
          ),
        ]),
        const SizedBox(height: 24),
        Icon(Icons.cloud_off_rounded, color: isDark ? Colors.white38 : Colors.grey, size: 32),
        const SizedBox(height: 8),
        Text(message, style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('重试')),
      ]),
    );
  }
}
