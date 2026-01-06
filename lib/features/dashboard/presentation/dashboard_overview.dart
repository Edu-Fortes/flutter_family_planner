import 'package:family_planner/features/dashboard/presentation/widgets/calendar_summary_widget.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/dashboard_widgets.dart'; // Clock, Quote
import 'widgets/weather_widget.dart';
import 'widgets/grocery_summary_widget.dart';
import 'widgets/priority_summary_widget.dart';

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final userEmail =
        Supabase.instance.client.auth.currentUser?.email ?? 'Family Member';

    // Calculate Greeting based on time
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour > 12) greeting = 'Good Afternoon';
    if (hour > 18) greeting = 'Good Evening';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- LEFT COLUMN (Info Stack) ---
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Area
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting,',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                          Text(
                            userEmail.split('@')[0], // Simple name extraction
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
                const QuoteWidget(),
                const SizedBox(height: 24),

                // 2. Action Summaries (Side by Side if space permits, or stacked)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Grocery Summary
                      Expanded(
                        child: Column(
                          children: [
                            const GrocerySummaryWidget(),
                            const SizedBox(height: 12),
                            // Fill remaining space with Priorities
                            Expanded(child: const PrioritySummaryWidget()),
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

          // --- RIGHT COLUMN (Calendar Lite) ---
          Expanded(
            flex: 1,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              // Using the Calendar Screen but constraining it to this box
              // Ideally, you'd strip the Scaffold/AppBar from CalendarScreen
              // so it fits purely as a widget here.
              child: const CalendarSummaryWidget(),
            ),
          ),
        ],
      ),
    );
  }
}
