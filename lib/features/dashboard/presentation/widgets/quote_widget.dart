import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/quote_repository.dart';

class QuoteWidget extends ConsumerStatefulWidget {
  const QuoteWidget({super.key});

  @override
  ConsumerState<QuoteWidget> createState() => _QuoteWidgetState();
}

class _QuoteWidgetState extends ConsumerState<QuoteWidget> {
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _scheduleMidnightRefresh();
  }

  void _scheduleMidnightRefresh() {
    // Check every minute if the day has changed
    _midnightTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      // If it's exactly 00:00 (or close to it), refresh the data
      if (now.hour == 0 && now.minute == 0) {
        // This forces the FutureProvider to fetch data again
        ref.invalidate(dailyQuoteProvider);
      }
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quoteAsync = ref.watch(dailyQuoteProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      // Use AnimatedSwitcher for a smooth transition when quote changes
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: quoteAsync.when(
          loading: () => const SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Text('Error loading quote: $err'),
          data: (quote) => Column(
            key: ValueKey(quote.text), // Key helps animation detect change
            children: [
              Text(
                '"${quote.text}"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Georgia', // Serif fonts look better for quotes
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "- ${quote.author}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
