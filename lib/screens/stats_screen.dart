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

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async { setState(() {}); }

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
            Text('每日活跃', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _BarChart(isDark: isDark),
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
  const _BarChart({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final data = [3, 7, 5, 12, 8, 15, 10];
    final days = ['一', '二', '三', '四', '五', '六', '日'];
    final maxVal = data.reduce((a, b) => a > b ? a : b).toDouble();
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
            children: List.generate(data.length, (i) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text('${data[i]}', style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey)),
                  const SizedBox(height: 4),
                  Container(
                    height: 100 * data[i] / maxVal,
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
        Row(children: List.generate(days.length, (i) => Expanded(
          child: Center(child: Text(days[i],
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey))),
        ))),
      ]),
    );
  }
}
