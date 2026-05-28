import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/repositories_providers.dart';
import '../../../domain/entities/task_item.dart';
import '../../../domain/enums/task_recurrence.dart';
import '../../../domain/enums/task_status.dart';
import '../../state/household_state.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.initialTask});

  final TaskItem? initialTask;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _xpCtrl;
  TaskStatus _status = TaskStatus.todo;
  TaskRecurrence _recurrence = TaskRecurrence.none;
  DateTime? _dueDate;
  String? _assignedUserId;
  bool _loading = false;

  bool get isEdit => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleCtrl = TextEditingController(text: task?.title ?? '');
    _descriptionCtrl = TextEditingController(text: task?.description ?? '');
    _xpCtrl = TextEditingController(text: (task?.xp ?? 10).toString());
    _status = task?.status ?? TaskStatus.todo;
    _recurrence = task?.recurrence ?? TaskRecurrence.none;
    _dueDate = task?.dueDate;
    _assignedUserId = task?.assignedUserId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _xpCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: _dueDate ?? now,
    );

    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final xp = int.tryParse(_xpCtrl.text.trim()) ?? 0;

    if (title.isEmpty || xp <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and a valid XP value are required.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = ref.read(taskRepositoryProvider);

      if (isEdit) {
        final task = widget.initialTask!;
        await repo.updateTask(
          taskId: task.id,
          title: title,
          description: _descriptionCtrl.text.trim(),
          xp: xp,
          assignedUserId: _assignedUserId,
          dueDate: _dueDate,
          status: _status,
          recurrence: _recurrence,
        );
      } else {
        final household = await ref.read(currentHouseholdProvider.future);
        if (household == null) throw Exception('Household not found.');

        await repo.createTask(
          householdId: household.id,
          title: title,
          description: _descriptionCtrl.text.trim(),
          xp: xp,
          assignedUserId: _assignedUserId,
          dueDate: _dueDate,
          recurrence: _recurrence,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving task: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit task' : 'New task')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionCtrl,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _xpCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'XP'),
          ),
          const SizedBox(height: 12),
          ref.watch(householdMembersProvider).when(
                data: (members) {
                  final hasCurrentSelection = _assignedUserId == null ||
                      members.any((m) => m.id == _assignedUserId);
                  final effectiveValue =
                      hasCurrentSelection ? _assignedUserId : null;

                  return DropdownButtonFormField<String?>(
                    initialValue: effectiveValue,
                    decoration: const InputDecoration(labelText: 'Assigned user'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ...members.map(
                        (m) => DropdownMenuItem<String?>(
                          value: m.id,
                          child: Text('${m.displayName} (@${m.username})'),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _assignedUserId = value),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading members: $e'),
              ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TaskStatus>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: TaskStatus.todo, child: Text('Todo')),
              DropdownMenuItem(
                  value: TaskStatus.inProgress, child: Text('In Progress')),
              DropdownMenuItem(
                  value: TaskStatus.completed, child: Text('Completed')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _status = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TaskRecurrence>(
            initialValue: _recurrence,
            decoration: const InputDecoration(labelText: 'Recurrence'),
            items: const [
              DropdownMenuItem(value: TaskRecurrence.none, child: Text('None')),
              DropdownMenuItem(
                  value: TaskRecurrence.daily, child: Text('Daily')),
              DropdownMenuItem(
                  value: TaskRecurrence.weekly, child: Text('Weekly')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _recurrence = value);
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            title: Text(_dueDate == null
                ? 'No due date'
                : 'Due date: ${_dueDate!.toLocal().toIso8601String().split('T').first}'),
            trailing: IconButton(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: Text(_loading ? 'Saving...' : 'Save'),
          ),
        ],
      ),
    );
  }
}
