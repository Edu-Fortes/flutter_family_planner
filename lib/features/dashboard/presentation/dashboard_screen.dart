import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/data/auth_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We can get the user safely because the Router protects this screen
    final user = Supabase.instance.client.auth.currentUser;
    final isGuest = user == null; // Should never happen due to router

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
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                // We will build the "Invite Member" UI here next
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Invite Family Member'),
            ),
          ],
        ),
      ),
    );
  }
}
