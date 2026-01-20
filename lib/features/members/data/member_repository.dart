import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; // 1. Use ImagePicker types

// --- MODEL ---
class FamilyMember {
  final String id;
  final String name;
  final String color;
  final String? avatarUrl;
  final String? profileId;
  final bool isVirtual;

  FamilyMember({
    required this.id,
    required this.name,
    required this.color,
    this.avatarUrl,
    this.profileId,
    required this.isVirtual,
  });

  int get colorValue {
    try {
      return int.parse(color.replaceFirst('#', 'FF'), radix: 16);
    } catch (_) {
      return 0xFF2196F3;
    }
  }

  factory FamilyMember.fromProfile(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'],
      name: json['display_name'] ?? json['username'] ?? 'User',
      color: json['color'] ?? '#2196F3',
      avatarUrl: json['avatar_url'],
      profileId: json['id'],
      isVirtual: false,
    );
  }

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

  Stream<List<FamilyMember>> getRealMembersStream() {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map(
          (data) => data.map((json) => FamilyMember.fromProfile(json)).toList(),
        );
  }

  Stream<List<FamilyMember>> getVirtualMembersStream() {
    return _client
        .from('family_members')
        .stream(primaryKey: ['id'])
        .map(
          (data) => data.map((json) => FamilyMember.fromVirtual(json)).toList(),
        );
  }

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

  // 2. FIXED UPLOAD METHOD FOR WEB & MOBILE
  Future<String?> uploadMemberAvatar(XFile image, String memberId) async {
    // A. Read the bytes (Works on Web & Mobile)
    final bytes = await image.readAsBytes();

    // B. Get extension safely
    final fileExt = image.name.split('.').last;
    final fileName =
        'members/$memberId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    try {
      // C. Use uploadBinary
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
      return _client.storage.from('avatars').getPublicUrl(fileName);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteMember(String memberId) async {
    await _client.from('family_members').delete().eq('id', memberId);
  }
}

final memberRepositoryProvider = Provider(
  (ref) => MemberRepository(Supabase.instance.client),
);

// --- THE PROVIDER MIXER ---
final realMembersProvider = StreamProvider((ref) {
  return ref.watch(memberRepositoryProvider).getRealMembersStream();
});

final virtualMembersProvider = StreamProvider((ref) {
  return ref.watch(memberRepositoryProvider).getVirtualMembersStream();
});

final allMembersProvider = Provider<AsyncValue<List<FamilyMember>>>((ref) {
  final realAsync = ref.watch(realMembersProvider);
  final virtualAsync = ref.watch(virtualMembersProvider);

  if (realAsync.isLoading || virtualAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (realAsync.hasError) {
    return AsyncValue.error(realAsync.error!, realAsync.stackTrace!);
  }
  if (virtualAsync.hasError) {
    return AsyncValue.error(virtualAsync.error!, virtualAsync.stackTrace!);
  }

  final real = realAsync.value ?? [];
  final virtual = virtualAsync.value ?? [];

  final combined = [...real, ...virtual];
  combined.sort((a, b) => a.name.compareTo(b.name));

  return AsyncValue.data(combined);
});
