import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/api_service.dart';
import '../widgets/common_widgets.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('新建提醒'),
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: '提醒标题', border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 24),
          const Text('可见性', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(children: [
            _chip('公开', _isPublic, () => setState(() => _isPublic = true)),
            const SizedBox(width: 8),
            _chip('私有', !_isPublic, () => setState(() => _isPublic = false)),
          ]),
          const SizedBox(height: 24),
          const Text('快捷选择', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(children: [
            _quickBtn('10分钟', const Duration(minutes: 10)),
            const SizedBox(width: 8),
            _quickBtn('1小时', const Duration(hours: 1)),
            const SizedBox(width: 8),
            _quickBtn('1天', const Duration(days: 1)),
          ]),
          const SizedBox(height: 16),
          const Text('精确选择', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(DateFormat('yyyy年MM月dd日').format(_selectedTime)),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.access_time, size: 16),
            label: Text(DateFormat('HH:mm').format(_selectedTime)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('提醒时间'),
              Text(DateFormat('MM-dd HH:mm').format(_selectedTime),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
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

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6366F1) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87)),
      ),
    );
  }

  Widget _quickBtn(String label, Duration duration) {
    return OutlinedButton(
      onPressed: () => setState(() => _selectedTime = DateTime.now().add(duration)),
      child: Text(label),
    );
  }
}
