import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroceryItem {
  final String id;
  final String name;
  final String category;
  final bool isCompleted;

  GroceryItem({
    required this.id,
    required this.name,
    required this.category,
    this.isCompleted = false,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: json['id'],
      name: json['name'],
      category: json['category'] ?? 'General',
      isCompleted: json['is_completed'] ?? false,
    );
  }
}

class GroceryRepository {
  final SupabaseClient _client;
  GroceryRepository(this._client);

  // Stream ordered by creation (newest on top) or category
  Stream<List<GroceryItem>> getGroceries() {
    return _client
        .from('grocery_items')
        .stream(primaryKey: ['id'])
        .order('is_completed', ascending: true) // Unchecked first
        .order('created_at', ascending: false) // Then newest first
        .map((data) => data.map((json) => GroceryItem.fromJson(json)).toList());
  }

  Future<void> addItem(String name, String category) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('grocery_items').insert({
      'name': name,
      'category': category,
      'created_by': user.id,
    });
  }

  Future<void> toggleStatus(String id, bool currentStatus) async {
    await _client
        .from('grocery_items')
        .update({'is_completed': !currentStatus})
        .eq('id', id);
  }

  Future<void> deleteItem(String id) async {
    await _client.from('grocery_items').delete().eq('id', id);
  }

  // Clean up: Delete all completed items at once
  Future<void> clearCompleted() async {
    await _client.from('grocery_items').delete().eq('is_completed', true);
  }
}

final groceryRepositoryProvider = Provider(
  (ref) => GroceryRepository(Supabase.instance.client),
);

final groceryStreamProvider = StreamProvider((ref) {
  return ref.watch(groceryRepositoryProvider).getGroceries();
});
