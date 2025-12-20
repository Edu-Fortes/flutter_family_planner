import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/data/auth_repository.dart';

class ProfileModel {
  final String id;
  final String username;
  final String role; // 'admin' or 'member'

  ProfileModel({required this.id, required this.username, required this.role});

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      username: json['username'] ?? '',
      role: json['role'] ?? 'member',
    );
  }
}

// Use autoDispose and watch authStateProvider
final profileProvider = FutureProvider.autoDispose<ProfileModel?>((ref) async {
  // 1. Watch the Auth State.
  // If the user logs out/in, this provider will rebuild automatically.
  ref.watch(authStateProvider);

  // 2. Get the current user
  final user = Supabase.instance.client.auth.currentUser;

  // 3. If no user (logged out), return null immediately
  if (user == null) return null;

  // 4. Fetch the FRESH profile for the NEW user
  final data = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();

  return ProfileModel.fromJson(data);
});
