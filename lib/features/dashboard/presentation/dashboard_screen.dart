import 'package:family_planner/features/calendar/presentation/calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../invitation/presentation/invitation_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We can get the user safely because the Router protects this screen
    final user = Supabase.instance.client.auth.currentUser;
    final isGuest = user == null; // Should never happen due to router
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Dashboard'),
        actions: [
          // THE LOGOUT BUTTON
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authRepositoryProvider).signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            Text('Welcome!', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Logged in as: ${isGuest ? "Guest" : user.email}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            // This button is visible to EVERYONE (Admin and Members)
            SizedBox(
              width: 250, // Fixed width for better look
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CalendarScreen()),
                  );
                },
                icon: const Icon(Icons.calendar_month),
                label: const Text('Open Calendar'),
              ),
            ),

            const SizedBox(height: 32),

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
                    label: const Text('Invite Family Member'),
                  );
                } else {
                  return const Text('Family Member View (No Admin Rights)');
                }
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => const Text('Could not load profile'),
            ),
          ],
        ),
      ),
    );
  }
}
