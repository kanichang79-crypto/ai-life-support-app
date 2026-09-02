import 'package:flutter/material.dart';

import '../models/alarm.dart';
import '../models/weekday.dart';
import '../repositories/alarm_repository.dart';
import '../services/notification_service.dart';
import 'alarm_edit_screen.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  final _repository = AlarmRepository();
  List<Alarm> _alarms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final alarms = await _repository.loadAlarms();
    setState(() {
      _alarms = alarms;
      _isLoading = false;
    });

    // 保存されているアラームの通知予約を端末側に同期し直す。
    for (final alarm in alarms) {
      if (alarm.isEnabled) {
        await NotificationService.instance.scheduleAlarm(alarm);
      }
    }
  }

  Future<void> _persist() => _repository.saveAlarms(_alarms);

  Future<void> _addAlarm() async {
    final result = await Navigator.of(context).push<Alarm>(
      MaterialPageRoute(builder: (_) => const AlarmEditScreen()),
    );
    if (result == null) return;

    setState(() => _alarms = [..._alarms, result]);
    await _persist();
    await NotificationService.instance.scheduleAlarm(result);
  }

  Future<void> _editAlarm(Alarm alarm) async {
    final result = await Navigator.of(context).push<Alarm>(
      MaterialPageRoute(builder: (_) => AlarmEditScreen(alarm: alarm)),
    );
    if (result == null) return;

    setState(() {
      _alarms = _alarms.map((a) => a.id == result.id ? result : a).toList();
    });
    await _persist();
    await NotificationService.instance.scheduleAlarm(result);
  }

  Future<void> _deleteAlarm(Alarm alarm) async {
    setState(() {
      _alarms = _alarms.where((a) => a.id != alarm.id).toList();
    });
    await _persist();
    await NotificationService.instance.cancelAlarm(alarm);
  }

  Future<void> _toggleEnabled(Alarm alarm, bool value) async {
    final updated = alarm.copyWith(isEnabled: value);
    setState(() {
      _alarms = _alarms.map((a) => a.id == alarm.id ? updated : a).toList();
    });
    await _persist();
    await NotificationService.instance.scheduleAlarm(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アラーム')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alarms.isEmpty
              ? const Center(child: Text('アラームがありません。右下の + から追加してください。'))
              : ListView.builder(
                  itemCount: _alarms.length,
                  itemBuilder: (context, index) {
                    final alarm = _alarms[index];
                    return _AlarmListTile(
                      alarm: alarm,
                      onToggle: (value) => _toggleEnabled(alarm, value),
                      onTap: () => _editAlarm(alarm),
                      onDelete: () => _deleteAlarm(alarm),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AlarmListTile extends StatelessWidget {
  final Alarm alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AlarmListTile({
    required this.alarm,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  String get _timeLabel {
    final hour = alarm.hour.toString().padLeft(2, '0');
    final minute = alarm.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get _repeatLabel {
    if (alarm.repeatDays.isEmpty) return '1回のみ';
    final sortedDays = alarm.repeatDays.toList()..sort();
    return sortedDays.map((d) => weekdayLabels[d]).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        title: Text(
          _timeLabel,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: alarm.isEnabled ? null : Theme.of(context).disabledColor,
              ),
        ),
        subtitle: Text(
          [if (alarm.label.isNotEmpty) alarm.label, _repeatLabel].join(' / '),
        ),
        trailing: Switch(value: alarm.isEnabled, onChanged: onToggle),
        onTap: onTap,
      ),
    );
  }
}
