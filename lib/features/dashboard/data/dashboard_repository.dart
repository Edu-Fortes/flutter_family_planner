import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- MODELS ---
class TaskItem {
  final int id;
  final String title;
  final int priority;
  final bool isCompleted;

  TaskItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.isCompleted,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'],
      title: json['title'],
      priority: json['priority'],
      isCompleted: json['is_completed'] ?? false,
    );
  }
}

// --- REPOSITORY ---
class DashboardRepository {
  final SupabaseClient _client;
  DashboardRepository(this._client);

  // Fetch only active tasks, sorted by Priority (1 first)
  Stream<List<TaskItem>> watchPriorityTasks() {
    return _client
        .from('priority_tasks')
        .stream(primaryKey: ['id'])
        .order('priority', ascending: true)
        .order('created_at', ascending: false)
        .map(
          (data) => data
              .where((element) => element['is_completed'] == false)
              .map((json) => TaskItem.fromJson(json))
              .toList(),
        );
  }

  // Fetch just the count of active grocery items
  Stream<int> watchGroceryCount() {
    return _client
        .from('grocery_items')
        .stream(primaryKey: ['id'])
        .map(
          (data) => data.where((item) => item['is_completed'] == false).length,
        );
  }

  Future<void> addTask(String title, int priority) async {
    await _client.from('priority_tasks').insert({
      'title': title,
      'priority': priority,
    });
  }

  Future<void> completeTask(int id) async {
    await _client
        .from('priority_tasks')
        .update({'is_completed': true})
        .eq('id', id);
  }

  // --- NEW: Update Task ---
  Future<void> updateTask(int id, String title, int priority) async {
    await _client
        .from('priority_tasks')
        .update({'title': title, 'priority': priority})
        .eq('id', id);
  }
}

// --- PROVIDERS ---
final dashboardRepoProvider = Provider(
  (ref) => DashboardRepository(Supabase.instance.client),
);

final priorityTasksProvider = StreamProvider(
  (ref) => ref.watch(dashboardRepoProvider).watchPriorityTasks(),
);
final groceryCountProvider = StreamProvider(
  (ref) => ref.watch(dashboardRepoProvider).watchGroceryCount(),
);
