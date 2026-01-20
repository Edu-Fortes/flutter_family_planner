import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; // Import ImagePicker
import '../../auth/data/auth_repository.dart';

class ProfileModel {
  final String id;
  final String username;
  final String? fullName;
  final String? displayName;
  final String color;
  final String? avatarUrl;
  final String role;

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
        })
        .eq('id', user.id);
  }

  // 3. Upload My Avatar (WEB & MOBILE FIX)
  Future<String?> uploadAvatar(XFile image) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    // A. Read Bytes
    final bytes = await image.readAsBytes();

    // B. Safe Filename
    final fileExt = image.name.split('.').last;
    final fileName =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    try {
      // C. Upload Binary
      await _client.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$fileExt',
            ),
          );

      final imageUrl = _client.storage.from('avatars').getPublicUrl(fileName);

      // Save URL to DB
      await _client
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', user.id);

      return imageUrl;
    } catch (e) {
      return null;
    }
  }
}

final profileRepositoryProvider = Provider(
  (ref) => ProfileRepository(Supabase.instance.client),
);

// Stream Provider
final profileProvider = StreamProvider.autoDispose<ProfileModel?>((ref) {
  ref.watch(authStateProvider);

  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return Stream.value(null);

  return Supabase.instance.client
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', user.id)
      .map((data) => data.isEmpty ? null : ProfileModel.fromJson(data.first));
});
