import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/api_service.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';

class CreateScreen extends StatefulWidget {
  final String uid;
  final VoidCallback onDone;
  final VoidCallback onBack;
  const CreateScreen({super.key, required this.uid, required this.onDone, required this.onBack});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _titleCtrl = TextEditingController();
  bool _isPublic = true;
  bool _saving = false;
  DateTime _selectedTime = DateTime.now().add(const Duration(hours: 1));

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedTime = DateTime(
          date.year, date.month, date.day, _selectedTime.hour, _selectedTime.minute));
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );
    if (time != null) {
      setState(() => _selectedTime = DateTime(
          _selectedTime.year, _selectedTime.month, _selectedTime.day, time.hour, time.minute));
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ApiService.createReminder(
          _titleCtrl.text.trim(), _selectedTime.millisecondsSinceEpoch, _isPublic);
      widget.onDone();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('新建提醒'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: widget.onBack),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: '提醒事件',
              prefixIcon: Icon(Icons.title_rounded, size: 18),
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          Text('可见性', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Row(children: [
            _chip('公开', _isPublic, () => setState(() => _isPublic = true), isDark),
            const SizedBox(width: 8),
            _chip('私有', !_isPublic, () => setState(() => _isPublic = false), isDark),
          ]),
          const SizedBox(height: 24),
          Text('快捷选择', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Row(children: [
            _quickBtn('10分钟', const Duration(minutes: 10), isDark),
            const SizedBox(width: 8),
            _quickBtn('1小时', const Duration(hours: 1), isDark),
            const SizedBox(width: 8),
            _quickBtn('1天', const Duration(days: 1), isDark),
          ]),
          const SizedBox(height: 24),
          Text('精确选择', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _dateBtn(context)),
            const SizedBox(width: 8),
            Expanded(child: _timeBtn(context)),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kPrimary.withOpacity(0.2)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                const Icon(Icons.alarm_rounded, size: 16, color: kPrimary),
                const SizedBox(width: 8),
                const Text('提醒时间', style: TextStyle(fontWeight: FontWeight.w500)),
              ]),
              Text(DateFormat('MM-dd HH:mm').format(_selectedTime),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: kPrimary)),
            ]),
          ),
          const SizedBox(height: 32),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _titleCtrl,
            builder: (_, value, __) => GradientButton(
              text: '发布提醒',
              onPressed: value.text.trim().isEmpty || _saving ? null : _save,
              loading: _saving,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _dateBtn(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _pickDate,
      icon: const Icon(Icons.calendar_today_rounded, size: 15),
      label: Text(DateFormat('MM月dd日').format(_selectedTime)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: kPrimary),
        foregroundColor: kPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _timeBtn(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _pickTime,
      icon: const Icon(Icons.access_time_rounded, size: 15),
      label: Text(DateFormat('HH:mm').format(_selectedTime)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: kPrimary),
        foregroundColor: kPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? gradientPurple : null,
          color: selected ? null : (isDark ? Colors.white10 : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(100),
          boxShadow: selected ? [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        )),
      ),
    );
  }

  Widget _quickBtn(String label, Duration duration, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTime = DateTime.now().add(duration)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
          ),
          child: Center(child: Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF374151),
          ))),
        ),
      ),
    );
  }
}
