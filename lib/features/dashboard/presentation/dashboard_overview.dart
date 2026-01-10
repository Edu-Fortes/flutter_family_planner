import 'dart:async';
import 'package:family_planner/features/dashboard/presentation/widgets/calendar_summary_widget.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/big_clock_widget.dart';
import 'widgets/quote_widget.dart';
import 'widgets/weather_widget.dart';
import 'widgets/grocery_summary_widget.dart';
import 'widgets/priority_summary_widget.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  Timer? _greetingTimer;
  String _greeting = '';

  @override
  void initState() {
    super.initState();
    _scheduleNextGreetingUpdate(); // Start the optimized cycle
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  void _scheduleNextGreetingUpdate() {
    final now = DateTime.now();
    final hour = now.hour;

    // 1. Determine current greeting
    // 2. Determine when the NEXT change happens
    DateTime nextChange;

    if (hour < 12) {
      _greeting = 'Bom dia';
      // Next change is at 12:00 today
      nextChange = DateTime(now.year, now.month, now.day, 12, 0, 0);
    } else if (hour < 18) {
      _greeting = 'Boa tarde';
      // Next change is at 18:00 today
      nextChange = DateTime(now.year, now.month, now.day, 18, 0, 0);
    } else {
      _greeting = 'Boa noite';
      // Next change is at 00:00 tomorrow (Back to Bom dia)
      nextChange = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    }

    // Force rebuild with new text
    setState(() {});

    // 3. Calculate exact duration until that moment
    // Add 1 second buffer to ensure we don't fire 1ms too early
    final duration = nextChange.difference(now) + const Duration(seconds: 1);

    print("Current: $_greeting. Sleeping for ${duration.inMinutes} minutes.");

    // 4. Set ONE timer that wakes up exactly when needed
    _greetingTimer = Timer(duration, () {
      _scheduleNextGreetingUpdate(); // Recursively schedule the next one
    });
  }

  @override
  Widget build(BuildContext context) {
    final userEmail =
        Supabase.instance.client.auth.currentUser?.email ?? 'Family Member';

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
                          // OPTIMIZED GREETING
                          Text(
                            '$_greeting,',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                          Text(
                            userEmail.split('@')[0],
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

                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Expanded(
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
