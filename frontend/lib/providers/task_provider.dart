import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final searchQueryProvider = StateProvider<String>((ref) => '');
final filterStatusProvider = StateProvider<TaskStatus?>((ref) => null);

final tasksProvider = FutureProvider<List<TaskItem>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final search = ref.watch(searchQueryProvider);
  final status = ref.watch(filterStatusProvider);
  return await api.getTasks(search: search, status: status);
});

class TaskNotifier {
  final Ref ref;
  TaskNotifier(this.ref);

  Future<void> createTask(TaskItem task) async {
    final api = ref.read(apiServiceProvider);
    await api.createTask(task);
    ref.invalidate(tasksProvider);
  }

  Future<void> updateTask(TaskItem task) async {
    final api = ref.read(apiServiceProvider);
    await api.updateTask(task);
    ref.invalidate(tasksProvider);
  }

  Future<void> deleteTask(String id) async {
    final api = ref.read(apiServiceProvider);
    await api.deleteTask(id);
    ref.invalidate(tasksProvider);
  }

  Future<void> reorderTask(String id, double newIndex) async {
    final api = ref.read(apiServiceProvider);
    await api.reorderTask(id, newIndex);
    ref.invalidate(tasksProvider);
  }
}

final taskNotifierProvider = Provider<TaskNotifier>((ref) {
  return TaskNotifier(ref);
});
