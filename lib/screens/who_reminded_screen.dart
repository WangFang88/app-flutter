import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';

class WhoRemindedScreen extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  const WhoRemindedScreen({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final items = events.map((e) => RemindEvent.fromJson(e)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('谁提醒过我')),
      body: items.isEmpty
          ? const Center(child: Text('暂无提醒记录', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RemindEventCard(event: items[i]),
              ),
            ),
    );
  }
}

class _RemindEventCard extends StatelessWidget {
  final RemindEvent event;
  const _RemindEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat('MM-dd HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(event.at),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? kCardDark : kCardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.person_rounded, color: kPrimary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.reminderTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${event.userLabel} 提醒了你',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Text(time, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
