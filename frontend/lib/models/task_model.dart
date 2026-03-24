enum TaskStatus { todo, inProgress, done }

extension TaskStatusExtension on TaskStatus {
  String get name {
    switch (this) {
      case TaskStatus.todo:
        return 'To-Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  static TaskStatus fromString(String status) {
    if (status == 'To-Do') return TaskStatus.todo;
    if (status == 'In Progress') return TaskStatus.inProgress;
    if (status == 'Done') return TaskStatus.done;
    return TaskStatus.todo;
  }
}

class TaskItem {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskStatus status;
  final String? blockedById;
  final double orderIndex;
  final bool isRecurring;
  final String? recurrenceInterval; // 'Daily' or 'Weekly'

  TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.blockedById,
    required this.orderIndex,
    required this.isRecurring,
    this.recurrenceInterval,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['due_date']),
      status: TaskStatusExtension.fromString(json['status']),
      blockedById: json['blocked_by_id'],
      orderIndex: (json['order_index'] as num).toDouble(),
      isRecurring: json['is_recurring'] ?? false,
      recurrenceInterval: json['recurrence_interval'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String().split('T')[0],
      'status': status.name,
      'blocked_by_id': blockedById,
      'order_index': orderIndex,
      'is_recurring': isRecurring,
      'recurrence_interval': recurrenceInterval,
    };
  }
  
  TaskItem copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    String? blockedById,
    double? orderIndex,
    bool? isRecurring,
    String? recurrenceInterval,
  }) {
    return TaskItem(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedById: blockedById ?? this.blockedById,
      orderIndex: orderIndex ?? this.orderIndex,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
    );
  }
}
