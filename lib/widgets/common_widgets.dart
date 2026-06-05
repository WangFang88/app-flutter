import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../data/models.dart';
import 'package:intl/intl.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final int supporterCount;
  final VoidCallback onTap;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.supporterCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('MM-dd HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(reminder.scheduledAtMillis),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? kCardDark : kCardLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reminder.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.access_time_rounded, size: 13,
                        color: isDark ? const Color(0xFF636366) : const Color(0xFFAEAEB2)),
                    const SizedBox(width: 4),
                    Text(time, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        reminder.isPublic ? '公开' : '私有',
                        style: TextStyle(
                          fontSize: 11,
                          color: reminder.isPublic ? kPrimary : const Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            if (reminder.isPublic && supporterCount > 0)
              Text('$supporterCount',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kPrimary)),
          ],
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  const GradientButton({super.key, required this.text, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: enabled ? kPrimary : const Color(0xFFE5E5EA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(text,
                  style: TextStyle(
                    color: enabled ? Colors.white : const Color(0xFFAEAEB2),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  )),
        ),
      ),
    );
  }
}

class SkeletonCard extends StatefulWidget {
  const SkeletonCard({super.key});
  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: _anim,
      builder: (_, __) {
        final base = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
        final highlight = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7);
        final color = Color.lerp(base, highlight, _anim.value)!;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 16, width: 200, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 10),
            Container(height: 12, width: 120, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          ]),
        );
      },
    );
  }
}