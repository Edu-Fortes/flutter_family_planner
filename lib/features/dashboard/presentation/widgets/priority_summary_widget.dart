import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dashboard_repository.dart';

class PrioritySummaryWidget extends ConsumerWidget {
  const PrioritySummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We reuse the same provider, but the UI is simplified
    final tasksAsync = ref.watch(priorityTasksProvider);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.priority_high, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Top Priorities',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: tasksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Text('Error'),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return const Center(child: Text("All Clear!"));
                  }

                  // Take only the top 5 for the summary view
                  final topTasks = tasks.take(5).toList();

                  return ListView.builder(
                    itemCount: topTasks.length,
                    itemBuilder: (context, index) {
                      final task = topTasks[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: task.priority == 1
                                    ? Colors.red
                                    : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
