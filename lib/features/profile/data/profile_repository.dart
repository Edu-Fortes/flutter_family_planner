import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/data/auth_repository.dart';

class ProfileModel {
  final String id;
  final String username; // The unique handle (often used for login/display)
  final String? fullName; // "Eduardo Fortes"
  final String? displayName; // "Edu" (The short name shown on Dashboard)
  final String color; // Hex string
  final String? avatarUrl;
  final String role; // 'admin' or 'member'

  ProfileModel({
    required this.id,
    required this.username,
    this.fullName,
    this.displayName,
    this.color = '#2196F3',
    this.avatarUrl,
    required this.role,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      username: json['username'] ?? '',
      fullName: json['full_name'],
      displayName: json['display_name'],
      color: json['color'] ?? '#2196F3',
      avatarUrl: json['avatar_url'],
      role: json['role'] ?? 'member',
    );
  }
}

class ProfileRepository {
  final SupabaseClient _client;
  ProfileRepository(this._client);

  // 1. Fetch My Profile
  Future<ProfileModel?> getProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      return ProfileModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // 2. Update Text Data
  Future<void> updateProfile({
    required String fullName,
    required String displayName,
    required String color,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client
        .from('profiles')
        .update({
          'full_name': fullName,
          'display_name': displayName,
          'color': color,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  }

  // 3. Upload My Avatar
  Future<String?> uploadAvatar(File imageFile) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    // Path: avatars/USER_ID/timestamp.jpg
    final fileExt = imageFile.path.split('.').last;
    final fileName =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    try {
      await _client.storage
          .from('avatars')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = _client.storage.from('avatars').getPublicUrl(fileName);

      // Save URL to DB immediately
      await _client
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', user.id);

      return imageUrl;
    } catch (e) {
      // print('Upload Error: $e');
      return null;
    }
  }
}

final profileRepositoryProvider = Provider(
  (ref) => ProfileRepository(Supabase.instance.client),
);

// Stream Provider for Real-Time updates on the Dashboard
final profileProvider = StreamProvider.autoDispose<ProfileModel?>((ref) {
  ref.watch(authStateProvider); // Rebuild on logout/login

  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return Stream.value(null);

  return Supabase.instance.client
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', user.id)
      .map((data) => data.isEmpty ? null : ProfileModel.fromJson(data.first));
});
