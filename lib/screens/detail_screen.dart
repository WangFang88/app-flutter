import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/api_service.dart';
import '../data/models.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';

class DetailScreen extends StatefulWidget {
  final String reminderId;
  final String myUid;
  const DetailScreen({super.key, required this.reminderId, required this.myUid});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Reminder? _reminder;
  int _supporters = 0;
  bool _supported = false;
  bool _loading = true;
  bool _reminding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await ApiService.getReminder(widget.reminderId);
      final count = await ApiService.supporterCount(widget.reminderId);
      final has = await ApiService.hasSupported(widget.reminderId, widget.myUid);
      if (mounted) setState(() { _reminder = r; _supporters = count; _supported = has; });
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _remind() async {
    setState(() => _reminding = true);
    await ApiService.remindOnce(widget.reminderId);
    final count = await ApiService.supporterCount(widget.reminderId);
    if (mounted) setState(() { _supporters = count; _supported = true; _reminding = false; });
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除提醒'),
        content: const Text('确定要删除这个提醒吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await ApiService.deleteReminder(widget.reminderId);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _edit() async {
    final r = _reminder;
    if (r == null) return;
    final titleCtrl = TextEditingController(text: r.title);
    var scheduledAt = r.scheduledAtMillis;
    var isPublic = r.isPublic;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('编辑提醒'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '标题')),
            const SizedBox(height: 12),
            Row(children: [
              const Text('公开'),
              const Spacer(),
              Switch(value: isPublic, onChanged: (v) => setS(() => isPublic = v)),
            ]),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                final dt = DateTime.fromMillisecondsSinceEpoch(scheduledAt);
                final date = await showDatePicker(context: ctx, initialDate: dt, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (date != null) {
                  final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(dt));
                  if (time != null) {
                    setS(() => scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute).millisecondsSinceEpoch);
                  }
                }
              },
              child: Text(DateFormat('MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(scheduledAt))),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(
              onPressed: () async {
                await ApiService.updateReminder(r.id, title: titleCtrl.text.trim(), scheduledAt: scheduledAt, isPublic: isPublic);
                Navigator.pop(ctx);
                _load();
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _reminder;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('提醒详情'),
        actions: r?.authorId == widget.myUid ? [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _edit),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ] : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : r == null
              ? const Center(child: Text('加载失败'))
              : SingleChildScrollView(
                  child: Column(children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(32, 48, 32, 40),
                      decoration: const BoxDecoration(
                        gradient: gradientHeader,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                      ),
                      child: Column(children: [
                        Text(DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(r.scheduledAtMillis)),
                            style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
                        const SizedBox(height: 4),
                        Text(DateFormat('yyyy年MM月dd日').format(DateTime.fromMillisecondsSinceEpoch(r.scheduledAtMillis)),
                            style: const TextStyle(color: Colors.white70, fontSize: 15)),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SizedBox(height: 4),
                        Text(r.title, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 20),
                        // 提醒强度进度条
                        Row(children: [
                          const Icon(Icons.people_rounded, size: 16, color: kPrimary),
                          const SizedBox(width: 6),
                          Text('提醒强度：$_supporters 人',
                              style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w600)),
                        ]),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: LinearProgressIndicator(
                            value: (_supporters.clamp(0, 10)) / 10.0,
                            minHeight: 8,
                            backgroundColor: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                            valueColor: const AlwaysStoppedAnimation(kPrimary),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (r.authorId != widget.myUid)
                          _supported
                              ? Container(
                                  width: double.infinity,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Icon(Icons.check_circle_rounded, color: kPrimary, size: 20),
                                    SizedBox(width: 8),
                                    Text('已提醒', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600)),
                                  ]),
                                )
                              : GradientButton(text: '提醒他', onPressed: _reminding ? null : _remind, loading: _reminding),
                      ]),
                    ),
                  ]),
                ),
    );
  }
}
