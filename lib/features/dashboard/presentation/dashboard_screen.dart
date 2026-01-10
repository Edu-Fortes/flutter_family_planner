import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- FEATURE IMPORTS ---
import '../../auth/data/auth_repository.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../grocery/presentation/grocery_screen.dart';
import '../../members/presentation/member_screen.dart';
import '../../invitation/presentation/invitation_screen.dart';
import '../../profile/data/profile_repository.dart';
import '../../tasks/presentation/tasks_screen.dart'; // <--- The New Tasks Screen

// --- WIDGET IMPORTS ---
import 'dashboard_overview.dart'; // <--- The New "Command Center" Desktop Widget

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // ============================================================
          // 🖥️ DESKTOP VIEW (> 800px) - "The Command Center"
          // ============================================================
          if (constraints.maxWidth > 800) {
            final desktopPages = [
              const DashboardOverview(), // Index 0: Summary Widget (Clock, Weather, etc.)
              const TasksScreen(), // Index 1: Dedicated Task Manager
              const GroceryScreen(), // Index 2: Full List
              const CalendarScreen(), // Index 3: Full Calendar
              const MemberScreen(), // Index 4: Family Management
            ];

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
                      icon: Icon(Icons.dashboard),
                      label: Text('Painel'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.check_circle_outlined),
                      label: Text('Tarefas'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.shopping_cart),
                      label: Text('Mercado'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_month),
                      label: Text('Calendário'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people),
                      label: Text('Família'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  // Safety check to prevent index out of bounds when switching views
                  child:
                      desktopPages[_selectedIndex >= desktopPages.length
                          ? 0
                          : _selectedIndex],
                ),
              ],
            );
          }
          // ============================================================
          // 📱 MOBILE VIEW (< 800px) - "Minimal & Focused"
          // ============================================================
          else {
            final mobilePages = [
              const _MobileMenuScreen(), // Index 0: Minimal Menu
              const TasksScreen(), // Index 1: Tasks
              const GroceryScreen(), // Index 2: Grocery
              const CalendarScreen(), // Index 3: Calendar
            ];

            // Ensure index is valid for mobile (e.g., if switching from Desktop tab #4)
            final mobileIndex = _selectedIndex >= mobilePages.length
                ? 0
                : _selectedIndex;

            return Scaffold(
              body: mobilePages[mobileIndex],
              bottomNavigationBar: NavigationBar(
                selectedIndex: mobileIndex,
                onDestinationSelected: (index) =>
                    setState(() => _selectedIndex = index),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Início',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.check_circle_outlined),
                    selectedIcon: Icon(Icons.check_circle),
                    label: 'Tarefas',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.shopping_cart_outlined),
                    selectedIcon: Icon(Icons.shopping_cart),
                    label: 'Mercado',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month),
                    label: 'Agenda',
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
// 📱 MOBILE HOME SCREEN (Restored Minimal Version)
// -----------------------------------------------------------------------------
class _MobileMenuScreen extends ConsumerWidget {
  const _MobileMenuScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planejamento Familiar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.family_restroom, size: 80, color: Colors.teal),
              const SizedBox(height: 20),
              Text(
                'Olá, ${user?.email?.split('@')[0] ?? 'Membro'}!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 40),

              // Quick Access Buttons for things NOT in the bottom bar
              _buildMenuButton(
                context,
                'Gerenciar Família',
                Icons.people,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MemberScreen()),
                ),
              ),

              // Admin Only: Invite Button
              profileAsync.when(
                data: (profile) {
                  if (profile?.role == 'admin') {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: _buildMenuButton(
                        context,
                        'Convites',
                        Icons.vpn_key,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InvitationScreen(),
                          ),
                        ),
                        isPrimary: true,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool isPrimary = false,
  }) {
    return SizedBox(
      width: 250,
      height: 50,
      child: isPrimary
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
            ),
    );
  }
}
