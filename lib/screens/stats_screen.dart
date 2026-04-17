import 'package:flutter/material.dart';
import '../data/api_service.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _published = 0;
  int _totalClicks = 0;
  List<int> _hourlyData = List.filled(24, 0);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final stats = await ApiService.getMyStats();
      if (mounted) setState(() {
        _published = stats['publishedWithReminds'] ?? 0;
        _totalClicks = stats['totalRemindClicks'] ?? 0;
        final hourly = stats['remindEventByHour'] as List<dynamic>?;
        if (hourly != null) {
          _hourlyData = hourly.map((e) => (e as num).toInt()).toList();
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('统计', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('数据概览', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: _MetricCard(label: '被提醒事项', value: '$_published', icon: Icons.task_alt_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _MetricCard(label: '提醒总人次', value: '$_totalClicks', icon: Icons.people_rounded)),
            ]),
            const SizedBox(height: 28),
            Text('每小时活跃', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _BarChart(isDark: isDark, data: _hourlyData),
          ]),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MetricCard({required this.label, required this.value, required this.icon});

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
    );
  }
}

class _BarChart extends StatelessWidget {
  final bool isDark;
  final List<int> data;
  const _BarChart({required this.isDark, required this.data});

  @override
  Widget build(BuildContext context) {
    // 显示8个时间段：0,3,6,9,12,15,18,21时
    final slots = List.generate(8, (i) => i * 3);
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
      child: Column(children: [
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(values.length, (i) => Expanded(
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
    );
  }
}
