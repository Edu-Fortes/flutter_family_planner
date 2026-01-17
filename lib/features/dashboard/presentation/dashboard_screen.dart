import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';

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
import 'widgets/grocery_summary_widget.dart';
import '../../calendar/data/calendar_repository.dart';
import '../../members/data/member_repository.dart';
import '../../dashboard/data/dashboard_repository.dart'; //

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
          // 🖥️ DESKTOP VIEW (> 800px)
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
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 72, maxWidth: 80),
                  child: Column(
                    children: [
                      Expanded(
                        child: NavigationRail(
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: (int index) {
                            setState(() => _selectedIndex = index);
                          },
                          labelType: NavigationRailLabelType.none,
                          groupAlignment: -1.0,
                          leading: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Icon(
                              Icons.family_restroom,
                              size: 32,
                              color: Colors.blue,
                            ),
                          ),
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

                      const Divider(indent: 10, endIndent: 10),
                      const SizedBox(height: 10),

                      // Desktop Popup
                      PopupMenuButton<String>(
                        tooltip: 'Menu de Perfil',
                        offset: const Offset(50, -100),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) {
                          final profile = ref.read(profileProvider).value;
                          final isAdmin = profile?.role == 'admin';
                          return [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.person, color: Colors.blue),
                                  SizedBox(width: 12),
                                  Text('Editar Perfil'),
                                ],
                              ),
                            ),
                            if (isAdmin)
                              const PopupMenuItem(
                                value: 'invite',
                                child: Row(
                                  children: [
                                    Icon(Icons.vpn_key, color: Colors.green),
                                    SizedBox(width: 12),
                                    Text('Convites'),
                                  ],
                                ),
                              ),
                          ];
                        },
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            );
                          } else if (value == 'invite') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InvitationScreen(),
                              ),
                            );
                          }
                        },
                        child: const _MiniProfileAvatar(onTap: null),
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
          // 📱 MOBILE VIEW (< 800px)
          // ============================================================
          else {
            final mobilePages = [
              const _MobileDashboardScreen(),
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
// 📱 MOBILE DASHBOARD
// -----------------------------------------------------------------------------
class _MobileDashboardScreen extends ConsumerWidget {
  const _MobileDashboardScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visão Geral'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: PopupMenuButton<String>(
              tooltip: 'Menu',
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) {
                final profile = ref.read(profileProvider).value;
                final isAdmin = profile?.role == 'admin';

                return [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue),
                        SizedBox(width: 12),
                        Text('Editar Perfil'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'family',
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Colors.orange),
                        SizedBox(width: 12),
                        Text('Gerenciar Família'),
                      ],
                    ),
                  ),
                  if (isAdmin)
                    const PopupMenuItem(
                      value: 'invite',
                      child: Row(
                        children: [
                          Icon(Icons.vpn_key, color: Colors.green),
                          SizedBox(width: 12),
                          Text('Convites'),
                        ],
                      ),
                    ),
                ];
              },
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                } else if (value == 'family') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MemberScreen()),
                  );
                } else if (value == 'invite') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InvitationScreen()),
                  );
                }
              },
              child: const _MiniProfileAvatar(onTap: null),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Agenda (Today Only)
            Expanded(flex: 3, child: _MobileAgendaWidget()),
            SizedBox(height: 16),

            // 2. Summaries - STACKED IN COLUMN
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(child: GrocerySummaryWidget()),
                  SizedBox(height: 12),
                  Expanded(child: _MobilePrioritySummary()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🚨 NEW MOBILE PRIORITY WIDGET (Counter Only)
// -----------------------------------------------------------------------------
class _MobilePrioritySummary extends ConsumerWidget {
  const _MobilePrioritySummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Correctly watch the provider from dashboard_repository.dart
    final tasksAsync = ref.watch(priorityTasksProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Icon(Icons.error, color: Colors.grey)),
        data: (tasks) {
          // Count tasks. Assuming all tasks in this provider are "Priority" ones.
          // If you need to filter for High Priority (1), use: .where((t) => t.priority == 1)
          final count = tasks.length;

          return Row(
            // Using Row to center content nicely
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.flag_rounded,
                size: 28,
                color: Colors.red,
              ), // Red flag for priority
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Prioridades',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 📅 MOBILE AGENDA WIDGET
// -----------------------------------------------------------------------------
class _MobileAgendaWidget extends ConsumerWidget {
  const _MobileAgendaWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsStreamProvider);
    final membersAsync = ref.watch(allMembersProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Text(
              'Agenda de Hoje',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(child: Text('Erro ao carregar')),
              data: (events) {
                final members = membersAsync.value ?? [];

                return SfCalendar(
                  view: CalendarView.schedule,
                  dataSource: _MobileCalendarDataSource(events, members),
                  headerHeight: 0,
                  viewHeaderHeight: 0,
                  minDate: DateTime.now(),
                  maxDate: DateTime.now().add(const Duration(days: 1)),

                  scheduleViewSettings: const ScheduleViewSettings(
                    appointmentItemHeight: 60,
                    hideEmptyScheduleWeek: true,
                    monthHeaderSettings: MonthHeaderSettings(height: 0),
                  ),

                  appointmentBuilder: (context, details) {
                    final event = details.appointments.first as FamilyEvent;
                    FamilyMember? member;
                    if (event.assignedToMemberId != null) {
                      try {
                        member = members.firstWhere(
                          (m) =>
                              m.id == event.assignedToMemberId ||
                              m.profileId == event.assignedToMemberId,
                        );
                      } catch (_) {}
                    }
                    final color = member != null
                        ? Color(member.colorValue)
                        : Colors.blue;

                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(color: color, width: 4),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      margin: const EdgeInsets.only(
                        bottom: 4,
                        top: 4,
                        left: 8,
                        right: 8,
                      ),
                      child: Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('HH:mm').format(event.startTime),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat('HH:mm').format(event.endTime),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (member != null)
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: color.withValues(alpha: 0.2),
                              backgroundImage: member.avatarUrl != null
                                  ? NetworkImage(member.avatarUrl!)
                                  : null,
                              child: member.avatarUrl == null
                                  ? Text(
                                      member.name[0],
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileCalendarDataSource extends CalendarDataSource {
  final List<FamilyMember> members;
  _MobileCalendarDataSource(List<FamilyEvent> source, this.members) {
    appointments = source;
  }
  @override
  DateTime getStartTime(int index) =>
      (appointments![index] as FamilyEvent).startTime;
  @override
  DateTime getEndTime(int index) =>
      (appointments![index] as FamilyEvent).endTime;
  @override
  String getSubject(int index) => (appointments![index] as FamilyEvent).title;
  @override
  bool isAllDay(int index) => (appointments![index] as FamilyEvent).isAllDay;
}

// -----------------------------------------------------------------------------
// 🔹 HELPER: Mini Avatar
// -----------------------------------------------------------------------------
class _MiniProfileAvatar extends ConsumerWidget {
  final VoidCallback? onTap;
  const _MiniProfileAvatar({this.onTap});

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
