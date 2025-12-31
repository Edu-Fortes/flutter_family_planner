import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/grocery_repository.dart';

class GroceryScreen extends ConsumerStatefulWidget {
  const GroceryScreen({super.key});

  @override
  ConsumerState<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends ConsumerState<GroceryScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode(); // 1. Focus Node to control keyboard

  String _selectedCategory = 'Geral';

  final List<String> _categories = [
    'Geral',
    'Produção',
    'Laticínios',
    'Carnes',
    'Padaria',
    'Congelados',
    'Produtos para casa',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose(); // Don't forget to dispose it!
    super.dispose();
  }

  void _addItem() {
    if (_textController.text.trim().isEmpty) return;

    ref
        .read(groceryRepositoryProvider)
        .addItem(_textController.text.trim(), _selectedCategory);

    _textController.clear();

    // 2. Reset category but KEEP FOCUS for rapid entry
    setState(() {
      _selectedCategory = 'Geral';
    });
    _focusNode.requestFocus();
  }

  Future<void> _confirmClear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar itens completos?'),
        content: const Text(
          'Isso ira apagar todos os itens marcados como completos.',
        ),
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

  @override
  Widget build(BuildContext context) {
    final groceryAsync = ref.watch(groceryStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Compras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Limpar Itens Completos',
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: groceryAsync.when(
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
                  padding: const EdgeInsets.only(
                    bottom: 140,
                  ), // Increased padding for taller input area
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
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
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
          ),

          // --- REFACTORED INPUT AREA ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.1,
                  ), // Updated for newer Flutter
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3. Categories WRAP (Replaces ScrollView + Row)
                  // This ensures all chips are visible by flowing to next line
                  Wrap(
                    spacing: 8.0, // Gap between chips horizontally
                    runSpacing: 0.0, // Gap between lines vertically
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = category);
                          }
                        },
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : null,
                          fontSize: 12, // Slightly smaller text to fit more
                        ),
                        checkmarkColor: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer,
                        // Make chips slightly more compact
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode, // Attach the FocusNode
                          textCapitalization: TextCapitalization.sentences,
                          // 4. Change keyboard action to "Go" or "Next"
                          textInputAction: TextInputAction.go,
                          decoration: const InputDecoration(
                            hintText: 'Adicione um item...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _addItem(),
                        ),
                      ),
                      const SizedBox(width: 12),

                      IconButton.filled(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        iconSize: 28,
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
