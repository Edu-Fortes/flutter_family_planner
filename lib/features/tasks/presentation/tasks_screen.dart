import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/data/dashboard_repository.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(priorityTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tarefas Prioritárias')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context, ref),
        label: const Text('Nova Tarefa'),
        icon: const Icon(Icons.add),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text('Sem tarefas! Aproveite seu dia.'),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getPriorityColor(task.priority),
                    child: Text(
                      '${task.priority}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    task.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    task.priority == 1
                        ? 'Alta Prioridade'
                        : 'Prioridade Normal',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () =>
                        ref.read(dashboardRepoProvider).completeTask(task.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getPriorityColor(int p) {
    switch (p) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    int selectedPriority = 1; // Default High

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nova Tarefa Prioritária'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Título da Tarefa',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Nível de Prioridade:'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [1, 2, 3].map((p) {
                  return ChoiceChip(
                    label: Text(
                      p == 1
                          ? 'Alta'
                          : p == 2
                          ? 'Média'
                          : 'Baixa',
                    ),
                    selected: selectedPriority == p,
                    onSelected: (val) {
                      if (val) setState(() => selectedPriority = p);
                    },
                    selectedColor: _getPriorityColor(p).withValues(alpha: 0.3),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  ref
                      .read(dashboardRepoProvider)
                      .addTask(controller.text, selectedPriority);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
