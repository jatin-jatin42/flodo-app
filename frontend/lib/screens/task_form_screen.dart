import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final TaskItem? task;
  const TaskFormScreen({Key? key, this.task}) : super(key: key);

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descController;
  
  DateTime _dueDate = DateTime.now();
  TaskStatus _status = TaskStatus.todo;
  String? _blockedById;
  bool _isRecurring = false;
  String? _recurrenceInterval = 'Daily';
  
  bool _isLoading = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(text: widget.task?.description ?? '');
    
    if (widget.task != null) {
      _dueDate = widget.task!.dueDate;
      _status = widget.task!.status;
      _blockedById = widget.task!.blockedById;
      _isRecurring = widget.task!.isRecurring;
      _recurrenceInterval = widget.task!.recurrenceInterval ?? 'Daily';
    } else {
      _loadDraft();
    }
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _titleController.text = prefs.getString('draft_title') ?? '';
      _descController.text = prefs.getString('draft_desc') ?? '';
      final draftDate = prefs.getString('draft_date');
      if (draftDate != null) {
        _dueDate = DateTime.parse(draftDate);
      }
    });
  }

  Future<void> _saveDraft() async {
    if (widget.task != null || _isLoading) return; // Don't draft edits or if already saving
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_title', _titleController.text);
    await prefs.setString('draft_desc', _descController.text);
    await prefs.setString('draft_date', _dueDate.toIso8601String());
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_title');
    await prefs.remove('draft_desc');
    await prefs.remove('draft_date');
  }

  @override
  void dispose() {
    if (!_submitted) _saveDraft();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final taskItem = TaskItem(
        id: widget.task?.id ?? '',
        title: _titleController.text,
        description: _descController.text,
        dueDate: _dueDate,
        status: _status,
        blockedById: _blockedById,
        orderIndex: widget.task?.orderIndex ?? 0.0,
        isRecurring: _isRecurring,
        recurrenceInterval: _isRecurring ? _recurrenceInterval : null,
      );

      if (widget.task == null) {
        await ref.read(taskNotifierProvider).createTask(taskItem);
        _submitted = true;
        await _clearDraft();
      } else {
        _submitted = true;
        await ref.read(taskNotifierProvider).updateTask(taskItem);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Create Task' : 'Edit Task', style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.task != null && !_isLoading)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                setState(() => _isLoading = true);
                try {
                  await ref.read(taskNotifierProvider).deleteTask(widget.task!.id);
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      maxLines: 4,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade400, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      title: const Text('Due Date'),
                      subtitle: Text('${_dueDate.toLocal()}'.split(' ')[0]),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _dueDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TaskStatus>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                      items: TaskStatus.values.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.name),
                          )).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    tasksAsync.when(
                      data: (tasks) {
                        final otherTasks = tasks.where((t) => t.id != widget.task?.id).toList();
                        return DropdownButtonFormField<String?>(
                          value: _blockedById,
                          decoration: const InputDecoration(labelText: 'Blocked By (Optional)', border: OutlineInputBorder()),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('None')),
                            ...otherTasks.map((t) => DropdownMenuItem(
                                  value: t.id,
                                  child: Text(t.title),
                                ))
                          ],
                          onChanged: (val) => setState(() => _blockedById = val),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error loading tasks: $err'),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade400, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      title: const Text('Is Recurring?'),
                      value: _isRecurring,
                      onChanged: (val) => setState(() => _isRecurring = val),
                    ),
                    if (_isRecurring) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _recurrenceInterval ?? 'Daily',
                        decoration: const InputDecoration(labelText: 'Recurrence Interval', border: OutlineInputBorder()),
                        items: ['Daily', 'Weekly'].map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s),
                            )).toList(),
                        onChanged: (val) => setState(() => _recurrenceInterval = val),
                      ),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: Text(
                        _isLoading ? 'Waiting...' : 'Save',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
