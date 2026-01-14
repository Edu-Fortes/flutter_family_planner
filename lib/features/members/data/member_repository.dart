import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- MODEL ---
class FamilyMember {
  final String id;
  final String name;
  final String color;
  final String? avatarUrl;
  final String? profileId; // If populated, this is a Real User (Parent)
  final bool isVirtual; // true = Child, false = Real User

  FamilyMember({
    required this.id,
    required this.name,
    required this.color,
    this.avatarUrl,
    this.profileId,
    required this.isVirtual,
  });

  // Helper: Color conversion
  int get colorValue {
    try {
      return int.parse(color.replaceFirst('#', 'FF'), radix: 16);
    } catch (_) {
      return 0xFF2196F3;
    }
  }

  // 1. Factory for REAL Users (Profiles Table)
  factory FamilyMember.fromProfile(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'],
      // Prefer display_name, fallback to username
      name: json['display_name'] ?? json['username'] ?? 'User',
      color: json['color'] ?? '#2196F3',
      avatarUrl: json['avatar_url'],
      profileId: json['id'], // It links to itself
      isVirtual: false,
    );
  }

  // 2. Factory for VIRTUAL Users (Family Members Table)
  factory FamilyMember.fromVirtual(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'],
      name: json['name'] ?? 'Membro',
      color: json['color'] ?? '#FF9800',
      avatarUrl: json['avatar_url'],
      profileId: null,
      isVirtual: true,
    );
  }
}

// --- REPOSITORY ---
class MemberRepository {
  final SupabaseClient _client;
  MemberRepository(this._client);

  // 1. Stream REAL Users (Profiles)
  Stream<List<FamilyMember>> getRealMembersStream() {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map(
          (data) => data.map((json) => FamilyMember.fromProfile(json)).toList(),
        );
  }

  // 2. Stream VIRTUAL Users (Children)
  Stream<List<FamilyMember>> getVirtualMembersStream() {
    return _client
        .from('family_members')
        .stream(primaryKey: ['id'])
        .map(
          (data) => data.map((json) => FamilyMember.fromVirtual(json)).toList(),
        );
  }

  // 3. Add Virtual Member
  Future<void> addVirtualMember(String name, String color) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('family_members').insert({
      'name': name,
      'color': color,
      'is_child': true,
      'created_by': user.id,
    });
  }

  // 4. Update Virtual Member
  Future<void> updateVirtualMember({
    required String memberId,
    required String name,
    required String color,
    String? avatarUrl,
  }) async {
    await _client
        .from('family_members')
        .update({'name': name, 'color': color, 'avatar_url': avatarUrl})
        .eq('id', memberId);
  }

  // 5. Upload Child Avatar
  Future<String?> uploadMemberAvatar(File imageFile, String memberId) async {
    final fileExt = imageFile.path.split('.').last;
    final fileName =
        'members/$memberId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    try {
      await _client.storage
          .from('avatars')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );
      return _client.storage.from('avatars').getPublicUrl(fileName);
    } catch (e) {
      return null;
    }
  }

  // 6. Delete Virtual Member
  Future<void> deleteMember(String memberId) async {
    await _client.from('family_members').delete().eq('id', memberId);
  }
}

final memberRepositoryProvider = Provider(
  (ref) => MemberRepository(Supabase.instance.client),
);

// --- THE PROVIDER MIXER (No StreamGroup needed!) ---

// 1. Watch Real Users
final realMembersProvider = StreamProvider((ref) {
  return ref.watch(memberRepositoryProvider).getRealMembersStream();
});

// 2. Watch Virtual Users
final virtualMembersProvider = StreamProvider((ref) {
  return ref.watch(memberRepositoryProvider).getVirtualMembersStream();
});

// 3. Merge them into one list
final allMembersProvider = Provider<AsyncValue<List<FamilyMember>>>((ref) {
  final realAsync = ref.watch(realMembersProvider);
  final virtualAsync = ref.watch(virtualMembersProvider);

  // If either is loading, the whole list is loading
  if (realAsync.isLoading || virtualAsync.isLoading) {
    return const AsyncValue.loading();
  }

  // If error
  if (realAsync.hasError) {
    return AsyncValue.error(realAsync.error!, realAsync.stackTrace!);
  }
  if (virtualAsync.hasError) {
    return AsyncValue.error(virtualAsync.error!, virtualAsync.stackTrace!);
  }

  // Merge Data
  final real = realAsync.value ?? [];
  final virtual = virtualAsync.value ?? [];

  final combined = [...real, ...virtual];

  // Sort alphabetically by name
  combined.sort((a, b) => a.name.compareTo(b.name));

  return AsyncValue.data(combined);
});
