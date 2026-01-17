import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Import Riverpod
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your providers
import '../../profile/data/profile_repository.dart';
import 'widgets/calendar_summary_widget.dart';
import 'widgets/big_clock_widget.dart';
import 'widgets/quote_widget.dart';
import 'widgets/weather_widget.dart';
import 'widgets/grocery_summary_widget.dart';
import 'widgets/priority_summary_widget.dart';

// 2. Change to ConsumerStatefulWidget
class DashboardOverview extends ConsumerStatefulWidget {
  const DashboardOverview({super.key});

  @override
  ConsumerState<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends ConsumerState<DashboardOverview> {
  Timer? _greetingTimer;
  String _greeting = '';

  @override
  void initState() {
    super.initState();
    _scheduleNextGreetingUpdate();
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  void _scheduleNextGreetingUpdate() {
    final now = DateTime.now();
    final hour = now.hour;
    DateTime nextChange;

    if (hour < 12) {
      _greeting = 'Bom dia';
      nextChange = DateTime(now.year, now.month, now.day, 12, 0, 0);
    } else if (hour < 18) {
      _greeting = 'Boa tarde';
      nextChange = DateTime(now.year, now.month, now.day, 18, 0, 0);
    } else {
      _greeting = 'Boa noite';
      nextChange = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    }

    setState(() {});
    final duration = nextChange.difference(now) + const Duration(seconds: 1);
    _greetingTimer = Timer(duration, _scheduleNextGreetingUpdate);
  }

  @override
  Widget build(BuildContext context) {
    // 3. Watch the Profile Provider to get the real name
    final profileAsync = ref.watch(profileProvider);
    final currentUser = Supabase.instance.client.auth.currentUser;

    // Fallback logic: Display Name -> Full Name -> Username -> Email -> "Membro"
    final displayName =
        profileAsync.value?.displayName ??
        profileAsync.value?.fullName?.split(' ').first ??
        profileAsync.value?.username ??
        currentUser?.email?.split('@')[0] ??
        'Membro';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- LEFT COLUMN ---
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Area
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_greeting,',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                          // 4. Use the dynamic display name
                          Text(
                            displayName,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          const BigClockWidget(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    const SizedBox(width: 420, child: WeatherWidget()),
                  ],
                ),

                const SizedBox(height: 24),
                const Row(children: [Expanded(child: QuoteWidget())]),
                const SizedBox(height: 24),

                const Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            GrocerySummaryWidget(),
                            SizedBox(height: 12),
                            Expanded(child: PrioritySummaryWidget()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // --- RIGHT COLUMN ---
          Expanded(
            flex: 1,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const CalendarSummaryWidget(),
            ),
          ),
        ],
      ),
    );
  }
}
