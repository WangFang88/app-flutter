import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../data/models.dart';
import 'package:intl/intl.dart';

// 毛玻璃卡片
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const GlassCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _PressableScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? kCardDark.withOpacity(0.85) : kCardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.9),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(isDark ? 0.12 : 0.07),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

// 按压缩放反馈
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _PressableScale({required this.child, this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { _ctrl.forward(); HapticFeedback.lightImpact(); },
      onTapUp: (_) { _ctrl.reverse(); widget.onTap?.call(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// 提醒卡片
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
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reminder.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.access_time_rounded, size: 13,
                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
            const SizedBox(width: 4),
            Text(time, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: reminder.isPublic
                    ? kPrimary.withOpacity(0.12)
                    : Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  reminder.isPublic ? Icons.public_rounded : Icons.lock_rounded,
                  size: 10,
                  color: reminder.isPublic ? kPrimary : Colors.grey,
                ),
                const SizedBox(width: 3),
                Text(
                  reminder.isPublic ? '公开' : '私有',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: reminder.isPublic ? kPrimary : Colors.grey,
                  ),
                ),
              ]),
            ),
            const Spacer(),
            if (reminder.isPublic && supporterCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: gradientPurple,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text('$supporterCount 人已提醒',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
          ]),
        ],
      ),
    );
  }
}

// 渐变按钮（带光晕）
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  const GradientButton({super.key, required this.text, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return _PressableScale(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: enabled ? gradientPurple : null,
          color: enabled ? null : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(100),
          boxShadow: enabled
              ? [
                  BoxShadow(color: kPrimary.withOpacity(0.45), blurRadius: 16, offset: const Offset(0, 6)),
                ]
              : null,
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(text,
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.grey.shade500,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  )),
        ),
      ),
    );
  }
}

// 骨架屏单项
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
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final base = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200;
        final highlight = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100;
        final color = Color.lerp(base, highlight, _anim.value)!;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 16, width: 200, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 12),
            Container(height: 12, width: 120, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))),
          ]),
        );
      },
    );
  }
}
