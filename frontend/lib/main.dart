import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/task_list_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: FlodoTaskApp(),
    ),
  );
}

class FlodoTaskApp extends StatelessWidget {
  const FlodoTaskApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flodo Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TaskListScreen(),
    );
  }
}
