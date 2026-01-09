import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/grocery_repository.dart';

class GroceryScreen extends ConsumerStatefulWidget {
  const GroceryScreen({super.key});

  @override
  ConsumerState<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends ConsumerState<GroceryScreen> {
  String _activeFilter = 'Todos'; // Default filter

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

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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

    // --- 1. CALCULATE COUNTS ---
    final Map<String, int> totalCounts = {};
    final Map<String, int> cartCounts = {};

    totalCounts['Todos'] = allItems.length;
    cartCounts['Todos'] = allItems.where((i) => i.isCompleted).length;

    for (var cat in _categories) {
      final catItems = allItems.where((i) => i.category == cat);
      totalCounts[cat] = catItems.length;
      cartCounts[cat] = catItems.where((i) => i.isCompleted).length;
    }

    // --- 2. PREPARE SUBTITLE TEXT ---
    String subtitleText;
    if (_activeFilter == 'Todos') {
      final total = totalCounts['Todos'] ?? 0;
      final done = cartCounts['Todos'] ?? 0;
      subtitleText = 'Total: $done/$total comprados';
    } else {
      final total = totalCounts[_activeFilter] ?? 0;
      final done = cartCounts[_activeFilter] ?? 0;
      subtitleText = 'Filtro: $_activeFilter ($done/$total)';
    }

    // --- 3. FILTER THE LIST ---
    final visibleItems = _activeFilter == 'Todos'
        ? allItems
        : allItems.where((i) => i.category == _activeFilter).toList();

    return Scaffold(
      appBar: AppBar(
        // --- NEW: Title with Dynamic Counter ---
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lista de Compras'),
            Text(
              subtitleText, // Shows "Filtro: Carne (2/5)"
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          // Filter Button
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar por Categoria',
            onSelected: (String value) {
              setState(() {
                _activeFilter = value;
              });
            },
            itemBuilder: (BuildContext context) {
              final options = ['Todos', ..._categories];

              return options
                  .map((cat) {
                    final count = totalCounts[cat] ?? 0;
                    final completed = cartCounts[cat] ?? 0;

                    // Hide empty categories from menu (unless active)
                    if (count == 0 && cat != 'Todos' && cat != _activeFilter) {
                      return null;
                    }

                    return PopupMenuItem<String>(
                      value: cat,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(cat),
                          if (count > 0)
                            Text(
                              '($completed/$count)',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    );
                  })
                  .whereType<PopupMenuItem<String>>()
                  .toList();
            },
          ),

          // Clear Button
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Excluir Concluídos',
            onPressed: _confirmClear,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemSheet(context),
        label: const Text('Adicionar'),
        icon: const Icon(Icons.add_shopping_cart),
      ),

      body: Column(
        children: [
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
                              : 'Nenhum item de $_activeFilter.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 100),
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
                          // Only show subtitle if viewing "Todos"
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
