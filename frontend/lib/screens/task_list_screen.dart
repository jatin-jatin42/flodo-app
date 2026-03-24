import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../utils/debouncer.dart';
import 'task_form_screen.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final Debouncer _debouncer = Debouncer(milliseconds: 300);
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildStatusFilter(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                _debouncer.run(() {
                  ref.read(searchQueryProvider.notifier).state = value;
                });
              },
            ),
          ),
        ),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(child: Text("No tasks found."));
          }
          return ReorderableListView.builder(
            buildDefaultDragHandles: false,
            itemCount: tasks.length,
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final task = tasks[oldIndex];
              
              // Calculate new order logic
              double newOrderVal = 0;
              if (newIndex == 0) {
                newOrderVal = tasks.first.orderIndex - 1.0;
              } else if (newIndex == tasks.length - 1) {
                newOrderVal = tasks.last.orderIndex + 1.0;
              } else {
                final beforeTask = tasks[newIndex - 1 < oldIndex ? newIndex - 1 : newIndex];
                final afterTask = tasks[newIndex > oldIndex ? newIndex : newIndex + 1];
                newOrderVal = (beforeTask.orderIndex + afterTask.orderIndex) / 2.0;
              }

              ref.read(taskNotifierProvider).reorderTask(task.id, newOrderVal);
            },
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _buildTaskCard(task, tasks, index);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TaskFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusFilter() {
    final currentStatus = ref.watch(filterStatusProvider);
    return DropdownButton<TaskStatus?>(
      value: currentStatus,
      icon: const Icon(Icons.filter_list, color: Colors.white),
      dropdownColor: Colors.deepPurple.shade100,
      underline: const SizedBox(),
      items: [
        const DropdownMenuItem(value: null, child: Text("All")),
        ...TaskStatus.values.map((status) => DropdownMenuItem(
          value: status,
          child: Text(status.name),
        ))
      ],
      onChanged: (val) {
        ref.read(filterStatusProvider.notifier).state = val;
      },
    );
  }

  Widget _buildTaskCard(TaskItem task, List<TaskItem> allTasks, int index) {
    // Check if blocked by evaluating dependencies
    bool isBlocked = false;
    if (task.blockedById != null) {
      final blocker = allTasks.cast<TaskItem?>().firstWhere(
        (t) => t?.id == task.blockedById,
        orElse: () => null,
      );
      if (blocker != null && blocker.status != TaskStatus.done) {
        isBlocked = true;
      }
    }

    final query = ref.watch(searchQueryProvider);
    
    // Highlight logic for search title stretch goal
    List<TextSpan> titleSpans = [];
    if (query.isNotEmpty && task.title.toLowerCase().contains(query.toLowerCase())) {
      final startIndex = task.title.toLowerCase().indexOf(query.toLowerCase());
      final endIndex = startIndex + query.length;
      
      titleSpans.add(TextSpan(text: task.title.substring(0, startIndex)));
      titleSpans.add(TextSpan(
        text: task.title.substring(startIndex, endIndex),
        style: const TextStyle(backgroundColor: Colors.yellow, color: Colors.black),
      ));
      titleSpans.add(TextSpan(text: task.title.substring(endIndex)));
    } else {
      titleSpans.add(TextSpan(text: task.title));
    }

    return Opacity(
      key: ValueKey(task.id),
      opacity: isBlocked ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ListTile(
          onTap: isBlocked ? null : () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
            );
          },
          title: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                decoration: task.status == TaskStatus.done ? TextDecoration.lineThrough : null,
                color: Colors.black,
              ),
              children: titleSpans,
            ),
          ),
          subtitle: Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TaskStatusBadge(status: task.status),
              const SizedBox(width: 8),
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskStatusBadge extends StatelessWidget {
  final TaskStatus status;
  const _TaskStatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case TaskStatus.todo:
        color = Colors.grey;
        break;
      case TaskStatus.inProgress:
        color = Colors.blue;
        break;
      case TaskStatus.done:
        color = Colors.green;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.name,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
