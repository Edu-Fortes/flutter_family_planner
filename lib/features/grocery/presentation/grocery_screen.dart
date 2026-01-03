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
  final FocusNode _focusNode = FocusNode();

  // 1. STATE: Which category are we VIEWING? (Filter)
  String _activeFilter = 'Todos';

  // 2. STATE: Which category are we ADDING to? (Input)
  String _selectedInputCategory = 'Geral';

  final List<String> _categories = [
    'Geral',
    'Hortifruti',
    'Bebidas',
    'Carne',
    'Padaria',
    'Congelados',
    'Limpeza',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_textController.text.trim().isEmpty) return;

    ref
        .read(groceryRepositoryProvider)
        .addItem(_textController.text.trim(), _selectedInputCategory);

    _textController.clear();

    // UX Improvement: If we are looking at a specific filter (e.g., Dairy),
    // and we add a "Meat" item, we might want to switch the view so the user sees it?
    // For now, let's just keep the focus so they can keep typing.
    _focusNode.requestFocus();
  }

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

  @override
  Widget build(BuildContext context) {
    final groceryAsync = ref.watch(groceryStreamProvider);

    // 3. DATA PREP: Get the full list safely
    final allItems = groceryAsync.asData?.value ?? [];

    // 4. CALCULATE COUNTS DYNAMICALLY
    // We create a map to store "completed" and "total" for every category
    final Map<String, int> totalCounts = {};
    final Map<String, int> cartCounts = {};

    // Initialize counts for "All" and fixed categories
    totalCounts['All'] = allItems.length;
    cartCounts['All'] = allItems.where((i) => i.isCompleted).length;

    for (var cat in _categories) {
      final catItems = allItems.where((i) => i.category == cat);
      totalCounts[cat] = catItems.length;
      cartCounts[cat] = catItems.where((i) => i.isCompleted).length;
    }

    // 5. FILTER THE LIST based on _activeFilter
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
      body: Column(
        children: [
          // --- TOP FILTER BAR (WRAPPED) ---
          Container(
            width: double.infinity, // Ensure it fills width
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
            child: Wrap(
              spacing: 8.0, // Horizontal gap between chips
              runSpacing: 8.0, // Vertical gap when wrapping to new line
              children: [
                // "All" Chip
                _buildFilterChip(
                  'Todos',
                  cartCounts['All']!,
                  totalCounts['All']!,
                ),

                // Category Chips
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
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 140),
                    itemCount: visibleItems.length,
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
                          // Subtitle is redundant if we are already in a specific category filter,
                          // but helpful when in "All" view.
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

          // --- INPUT AREA ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
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
                  // Input Categories (For ADDING)
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 0.0,
                    children: _categories.map((category) {
                      final isSelected = _selectedInputCategory == category;
                      return ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedInputCategory = category);
                          }
                        },
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : null,
                          fontSize: 12,
                        ),
                        checkmarkColor: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer,
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
                          focusNode: _focusNode,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.go,
                          decoration: const InputDecoration(
                            hintText: 'Adicione um novo item...',
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

  // Helper Widget for the Top Filter Bar
  Widget _buildFilterChip(String label, int completed, int total) {
    final isSelected = _activeFilter == label;
    // Don't show "0/0" if it's empty, unless it's selected
    if (!isSelected && total == 0 && label != 'All') {
      return const SizedBox.shrink();
    }

    // REMOVED: Padding widget (Wrap handles spacing now)
    return FilterChip(
      label: Text('$label ($completed/$total)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _activeFilter = label;
        });
      },
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest, // Slightly darker than surface
      selectedColor: Theme.of(context).colorScheme.secondaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onSecondaryContainer
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      showCheckmark: false,
      visualDensity:
          VisualDensity.compact, // Make them slightly smaller to fit more
    );
  }
}
