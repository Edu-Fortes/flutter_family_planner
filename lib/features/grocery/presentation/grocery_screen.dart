import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/grocery_repository.dart';

class GroceryScreen extends ConsumerWidget {
  const GroceryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groceryAsync = ref.watch(groceryStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Compras'),
        actions: [
          // Clear Completed Button
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Limpar Concluídos',
            onPressed: () => _confirmClear(context, ref),
          ),
        ],
      ),
      body: groceryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_basket_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text('Sua lista está vazia!'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Dismissible(
                key: Key(item.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  ref.read(groceryRepositoryProvider).deleteItem(item.id);
                },
                child: CheckboxListTile(
                  title: Text(
                    item.name,
                    style: TextStyle(
                      decoration: item.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: item.isCompleted ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Text(
                    item.category,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  value: item.isCompleted,
                  onChanged: (val) {
                    ref
                        .read(groceryRepositoryProvider)
                        .toggleStatus(item.id, item.isCompleted);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedCategory = 'Geral';
    final categories = [
      'Geral',
      'Produtos',
      'Laticínios',
      'Carnes',
      'Padaria',
      'Congelados',
      'Casa e Limpeza',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Adicionar Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome do Item'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCategory = val!),
                decoration: const InputDecoration(labelText: 'Categoria'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                await ref
                    .read(groceryRepositoryProvider)
                    .addItem(nameController.text.trim(), selectedCategory);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar Concluídos?'),
        content: const Text('Isso removerá todos os itens marcados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(groceryRepositoryProvider).clearCompleted();
    }
  }
}
