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
import '../../tasks/presentation/tasks_screen.dart';
import '../../profile/presentation/edit_profile_screen.dart';

// --- WIDGET IMPORTS ---
import 'dashboard_overview.dart';

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
              const DashboardOverview(),
              const TasksScreen(),
              const GroceryScreen(),
              const CalendarScreen(),
              const MemberScreen(),
            ];

            return Row(
              children: [
                // SIDEBAR COLUMN: Rail (Top) + Footer (Bottom)
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 72, maxWidth: 80),
                  child: Column(
                    children: [
                      // 1. NAVIGATION RAIL (Takes available space)
                      Expanded(
                        child: NavigationRail(
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: (int index) {
                            setState(() => _selectedIndex = index);
                          },
                          labelType: NavigationRailLabelType.none, // Icons Only
                          groupAlignment: -1.0, // Top Aligned
                          leading: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Icon(
                              Icons.family_restroom,
                              size: 32,
                              color: Colors.blue,
                            ),
                          ),
                          // No trailing here (we put it in the column below)
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Icons.dashboard_outlined),
                              selectedIcon: Icon(Icons.dashboard),
                              label: Text('Painel'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.check_circle_outlined),
                              selectedIcon: Icon(Icons.check_circle),
                              label: Text('Tarefas'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.shopping_cart_outlined),
                              selectedIcon: Icon(Icons.shopping_cart),
                              label: Text('Mercado'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.calendar_month_outlined),
                              selectedIcon: Icon(Icons.calendar_month),
                              label: Text('Calendário'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.people_outline),
                              selectedIcon: Icon(Icons.people),
                              label: Text('Família'),
                            ),
                          ],
                        ),
                      ),

                      // 2. FOOTER (Pinned to Bottom)
                      // We use the Mini Avatar because the rail is narrow
                      const Divider(indent: 10, endIndent: 10),
                      const SizedBox(height: 10),

                      Tooltip(
                        message: 'Editar Perfil',
                        child: _MiniProfileAvatar(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.red),
                        tooltip: 'Sair',
                        onPressed: () =>
                            ref.read(authRepositoryProvider).signOut(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                const VerticalDivider(thickness: 1, width: 1),

                // MAIN CONTENT
                Expanded(
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
              const _MobileMenuScreen(),
              const TasksScreen(),
              const GroceryScreen(),
              const CalendarScreen(),
            ];

            final mobileIndex = _selectedIndex >= mobilePages.length
                ? 0
                : _selectedIndex;

            return Scaffold(
              body: mobilePages[mobileIndex],
              bottomNavigationBar: NavigationBar(
                selectedIndex: mobileIndex,
                onDestinationSelected: (index) =>
                    setState(() => _selectedIndex = index),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
// 📱 MOBILE HOME SCREEN
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
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _MiniProfileAvatar(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
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

              _buildMenuButton(
                context,
                'Gerenciar Família',
                Icons.people,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MemberScreen()),
                ),
              ),

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

// -----------------------------------------------------------------------------
// 🔹 HELPER: Mini Avatar (Used in both Desktop Rail and Mobile AppBar)
// -----------------------------------------------------------------------------
class _MiniProfileAvatar extends ConsumerWidget {
  final VoidCallback onTap;
  const _MiniProfileAvatar({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () =>
          const CircleAvatar(radius: 18, backgroundColor: Colors.transparent),
      error: (_, _) => const Icon(Icons.error),
      data: (profile) {
        if (profile == null) return const SizedBox();

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Color(
              int.parse(profile.color.replaceFirst('#', 'FF'), radix: 16),
            ),
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? Text(
                    (profile.displayName ?? profile.username)
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
