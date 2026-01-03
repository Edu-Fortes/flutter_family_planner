import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. The Model
class DailyQuote {
  final String author;
  final String text;

  DailyQuote({required this.author, required this.text});

  factory DailyQuote.fromJson(Map<String, dynamic> json) {
    return DailyQuote(
      author: json['autor'] ?? 'Desconhecido',
      text: json['frase'] ?? 'Nenhuma frase encontrada.',
    );
  }
}

// 2. The Repository
class QuoteRepository {
  final SupabaseClient _client;
  QuoteRepository(this._client);

  Future<DailyQuote> fetchDailyQuote() async {
    // Call the SQL function we created
    final response = await _client.rpc('get_daily_quote');

    // RPC returns a List (even if limit 1), so we take the first item
    if (response is List && response.isNotEmpty) {
      return DailyQuote.fromJson(response.first);
    }

    // Fallback if DB is empty
    return DailyQuote(
      author: "Sistema",
      text: "Adicione frases ao banco de dados!",
    );
  }
}

// 3. The Providers
final quoteRepositoryProvider = Provider((ref) {
  return QuoteRepository(Supabase.instance.client);
});

final dailyQuoteProvider = FutureProvider<DailyQuote>((ref) async {
  return ref.read(quoteRepositoryProvider).fetchDailyQuote();
});
