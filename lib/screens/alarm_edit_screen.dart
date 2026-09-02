import 'dart:math';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/alarm.dart';
import '../models/weekday.dart';

/// アラームの新規追加・編集を行う画面。
/// [alarm] を渡すと編集モード、渡さなければ新規追加モードになる。
class AlarmEditScreen extends StatefulWidget {
  final Alarm? alarm;

  const AlarmEditScreen({super.key, this.alarm});

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  late final TextEditingController _labelController;
  late TimeOfDay _time;
  late bool _isEnabled;
  late Set<int> _repeatDays;

  bool get _isEditing => widget.alarm != null;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.alarm?.label ?? '');
    _time = widget.alarm == null
        ? TimeOfDay.now()
        : TimeOfDay(hour: widget.alarm!.hour, minute: widget.alarm!.minute);
    _isEnabled = widget.alarm?.isEnabled ?? true;
    _repeatDays = {...?widget.alarm?.repeatDays};
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  void _toggleDay(int weekday) {
    setState(() {
      if (_repeatDays.contains(weekday)) {
        _repeatDays.remove(weekday);
      } else {
        _repeatDays.add(weekday);
      }
    });
  }

  void _submit() {
    final result = _isEditing
        ? widget.alarm!.copyWith(
            hour: _time.hour,
            minute: _time.minute,
            label: _labelController.text.trim(),
            isEnabled: _isEnabled,
            repeatDays: _repeatDays,
          )
        : Alarm(
            id: const Uuid().v4(),
            notificationBaseId: Random().nextInt(1000000),
            hour: _time.hour,
            minute: _time.minute,
            label: _labelController.text.trim(),
            isEnabled: _isEnabled,
            repeatDays: _repeatDays,
          );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'アラームを編集' : 'アラームを追加'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: TextButton(
              onPressed: _pickTime,
              child: Text(
                _time.format(context),
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'ラベル(任意)',
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('有効にする'),
            value: _isEnabled,
            onChanged: (value) => setState(() => _isEnabled = value),
          ),
          const SizedBox(height: 16),
          const Text('繰り返し(曜日を選択。未選択の場合は次回1回のみ鳴ります)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: weekdayLabels.entries.map((entry) {
              final selected = _repeatDays.contains(entry.key);
              return FilterChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: (_) => _toggleDay(entry.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submit,
            child: Text(_isEditing ? '保存する' : '追加する'),
          ),
        ],
      ),
    );
  }
}
