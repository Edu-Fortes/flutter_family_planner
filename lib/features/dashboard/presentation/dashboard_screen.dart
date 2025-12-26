import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import Features
import '../../auth/data/auth_repository.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../grocery/presentation/grocery_screen.dart';
import '../../members/presentation/member_screen.dart';
import '../../invitation/presentation/invitation_screen.dart'; // For invite tool
import '../../profile/data/profile_repository.dart'; // To check admin role

// Import Widgets
import 'widgets/dashboard_widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  // The list of pages for Mobile/Desktop navigation
  // Note: We use a method to regenerate this so we can access 'context' if needed
  List<Widget> _getPages() {
    return [
      const _HomeView(), // Index 0: The "Home" (Clock/Summary)
      const CalendarScreen(), // Index 1: Full Calendar
      const GroceryScreen(), // Index 2: Full Grocery List
      const MemberScreen(), // Index 3: Family Members
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            // --- DESKTOP VIEW (Raspberry Pi) ---
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() => _selectedIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Icon(Icons.family_restroom, size: 40),
                  ),
                  trailing: Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.logout),
                          onPressed: () =>
                              ref.read(authRepositoryProvider).signOut(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Início'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_month),
                      label: Text('Calendário'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.shopping_cart),
                      label: Text('Mercado'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people),
                      label: Text('Família'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                // Main Content Area
                Expanded(child: _getPages()[_selectedIndex]),
              ],
            );
          } else {
            // --- MOBILE VIEW ---
            // On Mobile, we don't show the "Clock" home screen as the default.
            // We default to the Calendar or Grocery list for quick access.
            // But to keep indices simple, we will map them:
            // 0=Home(Menu), 1=Calendar, 2=Grocery

            final mobilePages = [
              // Mobile "Home" is a simple menu, not the big clock
              const _MobileMenuScreen(),
              const CalendarScreen(),
              const GroceryScreen(),
            ];

            // Safety check for index
            final mobileIndex = _selectedIndex >= mobilePages.length
                ? 0
                : _selectedIndex;

            return Scaffold(
              body: mobilePages[mobileIndex],
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: mobileIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Início',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_month),
                    label: 'Calendário',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.shopping_cart),
                    label: 'Mercado',
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// INTERNAL VIEWS
// -----------------------------------------------------------------------------

/// THE DESKTOP "HOME" SCREEN (Clock, Quotes, Quick Actions)
class _HomeView extends ConsumerWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      // No AppBar needed here, the NavRail is the "AppBar"
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. The Big Clock
              const BigClockWidget(),
              const SizedBox(height: 40),

              // 2. The Quote
              const QuoteWidget(),
              const SizedBox(height: 60),

              // 3. Welcome Text
              Text(
                'Welcome, ${user?.email}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),

              // 4. Admin Only: Invite Button
              profileAsync.when(
                data: (profile) {
                  if (profile?.role == 'admin') {
                    return FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InvitationScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Generate Invite Code'),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// THE MOBILE "HOME" SCREEN (Simple Menu)
class _MobileMenuScreen extends ConsumerWidget {
  const _MobileMenuScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_filled, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 20),
            const Text('Welcome Home!'),
            const SizedBox(height: 40),

            // Link to Family Management (Not in Bottom Bar)
            SizedBox(
              width: 250,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MemberScreen()),
                  );
                },
                icon: const Icon(Icons.people),
                label: const Text('Manage Family'),
              ),
            ),

            const SizedBox(height: 16),

            // Admin Only: Invite Button
            profileAsync.when(
              data: (profile) {
                if (profile?.role == 'admin') {
                  return SizedBox(
                    width: 250,
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InvitationScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.vpn_key),
                      label: const Text('Invite Codes'),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
