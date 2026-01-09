import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/grocery_repository.dart';

class GroceryScreen extends ConsumerStatefulWidget {
  const GroceryScreen({super.key});

  @override
  ConsumerState<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends ConsumerState<GroceryScreen> {
  // 1. STATE: Which category are we VIEWING? (Filter)
  String _activeFilter = 'Todos';

  // Note: We removed the TextEditingController from here because
  // it now lives inside the _AddItemSheet widget.

  final List<String> _categories = [
    'Geral',
    'Hortifruti',
    'Bebidas',
    'Carne',
    'Padaria',
    'Congelados',
    'Limpeza',
  ];

  Future<void> _confirmClear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Concluídos?'),
        content: const Text('Isso removerá todos os itens marcados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(groceryRepositoryProvider).clearCompleted();
    }
  }

  // --- NEW: Method to open the Drawer ---
  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to expand with keyboard
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddItemSheet(categories: _categories),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groceryAsync = ref.watch(groceryStreamProvider);
    final allItems = groceryAsync.asData?.value ?? [];

    // --- CALCULATE COUNTS (Your original logic) ---
    final Map<String, int> totalCounts = {};
    final Map<String, int> cartCounts = {};

    totalCounts['All'] = allItems.length;
    cartCounts['All'] = allItems.where((i) => i.isCompleted).length;

    for (var cat in _categories) {
      final catItems = allItems.where((i) => i.category == cat);
      totalCounts[cat] = catItems.length;
      cartCounts[cat] = catItems.where((i) => i.isCompleted).length;
    }

    // --- FILTER LIST ---
    final visibleItems = _activeFilter == 'Todos'
        ? allItems
        : allItems.where((i) => i.category == _activeFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Compras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Excluir Concluídos',
            onPressed: _confirmClear,
          ),
        ],
      ),

      // --- NEW: Floating Action Button ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemSheet(context),
        label: const Text('Adicionar'),
        icon: const Icon(Icons.add_shopping_cart),
      ),

      body: Column(
        children: [
          // --- TOP FILTER BAR ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                _buildFilterChip(
                  'Todos',
                  cartCounts['All']!,
                  totalCounts['All']!,
                ),
                ..._categories.map((cat) {
                  return _buildFilterChip(
                    cat,
                    cartCounts[cat] ?? 0,
                    totalCounts[cat] ?? 0,
                  );
                }),
              ],
            ),
          ),

          // --- MAIN LIST ---
          Expanded(
            child: visibleItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_off,
                          size: 48,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _activeFilter == 'Todos'
                              ? 'Lista vazia!'
                              : 'Nenhum item de ${_activeFilter.toLowerCase()}.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    // Changed to separated for cleaner look
                    padding: const EdgeInsets.only(
                      bottom: 100,
                    ), // Extra space for FAB
                    itemCount: visibleItems.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = visibleItems[index];
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
                          ref
                              .read(groceryRepositoryProvider)
                              .deleteItem(item.id);
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
                          subtitle: _activeFilter == 'Todos'
                              ? Text(
                                  item.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                          value: item.isCompleted,
                          onChanged: (val) {
                            // Using toggleStatus as per your repository
                            ref
                                .read(groceryRepositoryProvider)
                                .toggleStatus(item.id, item.isCompleted);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int completed, int total) {
    final isSelected = _activeFilter == label;
    if (!isSelected && total == 0 && label != 'All') {
      return const SizedBox.shrink();
    }

    return FilterChip(
      label: Text('$label ($completed/$total)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _activeFilter = label);
      },
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      selectedColor: Theme.of(context).colorScheme.secondaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onSecondaryContainer
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
    );
  }
}

// -----------------------------------------------------------------------------
// NEW WIDGET: The Bottom Sheet Input (Continuous Entry Version)
// -----------------------------------------------------------------------------
class _AddItemSheet extends ConsumerStatefulWidget {
  final List<String> categories;
  const _AddItemSheet({required this.categories});

  @override
  ConsumerState<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<_AddItemSheet> {
  final _controller = TextEditingController();

  // 1. ADD FOCUS NODE
  // This allows us to keep the keyboard open after submitting
  final FocusNode _focusNode = FocusNode();

  String _selectedCategory = 'Geral';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose(); // Don't forget to dispose!
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) return;

    ref
        .read(groceryRepositoryProvider)
        .addItem(_controller.text.trim(), _selectedCategory);

    // 2. CONTINUOUS ENTRY LOGIC
    _controller.clear(); // Clear the text
    _focusNode.requestFocus(); // Keep the keyboard up!

    // We REMOVED Navigator.pop(context) here so the sheet stays open.
    // To close it, the user simply taps outside the sheet or swipes it down.
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: keyboardPadding + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header with "Done" button (Optional, but nice since we removed auto-close)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Novo Item', style: Theme.of(context).textTheme.titleLarge),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Concluir"),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Input Field
          TextField(
            controller: _controller,
            focusNode: _focusNode, // Attach the focus node
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction
                .go, // "Go" or "Next" feels right for rapid entry
            decoration: const InputDecoration(
              hintText: 'O que falta na despensa?',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.add),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),

          // Category Selector
          Text("Categoria:", style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),

          // 3. HORIZONTAL SCROLL FIX
          SingleChildScrollView(
            scrollDirection: Axis.horizontal, // Enables sliding
            child: Row(
              children: widget.categories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: _selectedCategory == cat,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat);
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Submit Button
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text(
              'Adicionar Outro',
            ), // Changed text to imply continuity
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ],
      ),
    );
  }
}
