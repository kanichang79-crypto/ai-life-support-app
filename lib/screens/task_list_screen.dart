import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../repositories/task_repository.dart';
import 'task_edit_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _repository = TaskRepository();
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _repository.loadTasks();
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> _persist() => _repository.saveTasks(_tasks);

  Future<void> _addTask() async {
    final result = await Navigator.of(context).push<Task>(
      MaterialPageRoute(builder: (_) => const TaskEditScreen()),
    );
    if (result == null) return;

    setState(() => _tasks = [..._tasks, result]);
    await _persist();
  }

  Future<void> _editTask(Task task) async {
    final result = await Navigator.of(context).push<Task>(
      MaterialPageRoute(builder: (_) => TaskEditScreen(task: task)),
    );
    if (result == null) return;

    setState(() {
      _tasks = _tasks.map((t) => t.id == result.id ? result : t).toList();
    });
    await _persist();
  }

  Future<void> _deleteTask(Task task) async {
    setState(() {
      _tasks = _tasks.where((t) => t.id != task.id).toList();
    });
    await _persist();
  }

  Future<void> _toggleDone(Task task, bool? value) async {
    setState(() {
      _tasks = _tasks
          .map((t) => t.id == task.id ? t.copyWith(isDone: value ?? false) : t)
          .toList();
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('タスク管理')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? const Center(child: Text('タスクがありません。右下の + から追加してください。'))
              : ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return _TaskListTile(
                      task: task,
                      onToggle: (value) => _toggleDone(task, value),
                      onTap: () => _editTask(task),
                      onDelete: () => _deleteTask(task),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TaskListTile extends StatelessWidget {
  final Task task;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TaskListTile({
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  bool get _isOverdue {
    if (task.isDone || task.dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = task.dueDate!;
    final dueDay = DateTime(due.year, due.month, due.day);
    return dueDay.isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: Checkbox(value: task.isDone, onChanged: onToggle),
        title: Text(
          task.title,
          style: task.isDone
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: task.dueDate == null
            ? null
            : Text(
                '期限: ${dateFormat.format(task.dueDate!)}',
                style: TextStyle(
                  color: _isOverdue ? Theme.of(context).colorScheme.error : null,
                ),
              ),
        onTap: onTap,
      ),
    );
  }
}
