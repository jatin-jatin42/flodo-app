import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';
import 'dart:async';

class ApiService {
  final String baseUrl = 'http://localhost:8000/tasks/';

  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<List<TaskItem>> getTasks({String? search, TaskStatus? status}) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status.name,
      });

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TaskItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<TaskItem> createTask(TaskItem task) async {
    await _simulateDelay(); // Simulated 2-second delay per requirement
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(task.toJson()),
      );
      if (response.statusCode == 200) {
        return TaskItem.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create task');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<TaskItem> updateTask(TaskItem task) async {
    await _simulateDelay(); // Simulated 2-second delay per requirement
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${task.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(task.toJson()),
      );
      if (response.statusCode == 200) {
        return TaskItem.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update task');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete task');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> reorderTask(String id, double newOrderIndex) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$id/reorder'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'new_order_index': newOrderIndex}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to reorder task');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
