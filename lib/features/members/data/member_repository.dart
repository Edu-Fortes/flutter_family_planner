import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FamilyMember {
  final String id;
  final String name;
  final String color;
  final bool isChild;
  final String? profileId;

  FamilyMember({
    required this.id,
    required this.name,
    required this.color,
    this.isChild = false,
    this.profileId,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'],
      name: json['name'],
      color: json['color'] ?? '#2196F3',
      isChild: json['is_child'] ?? false,
      profileId: json['profile_id'],
    );
  }

  // Helper: Convert Hex String to Integer for Flutter Color
  int get colorValue {
    final hex = color.replaceAll('#', '');
    return int.parse('FF$hex', radix: 16);
  }
}

class MemberRepository {
  final SupabaseClient _client;
  MemberRepository(this._client);

  // Stream of all family members (Real + Virtual)
  Stream<List<FamilyMember>> getMembers() {
    return _client
        .from('family_members')
        .stream(primaryKey: ['id'])
        .order('name')
        .map(
          (data) => data.map((json) => FamilyMember.fromJson(json)).toList(),
        );
  }

  // Admin: Create a "Virtual" member (e.g., Child)
  Future<void> addVirtualMember(
    String name,
    String colorHex, {
    bool isChild = true,
  }) async {
    await _client.from('family_members').insert({
      'name': name,
      'color': colorHex,
      'is_child': isChild,
      'profile_id': null, // No login account
    });
  }

  // Update Name and Color
  Future<void> updateMember(
    String memberId,
    String newName,
    String newColorHex,
  ) async {
    // If this member is linked to a profile (Real User), we should also update the profile name
    // But for simplicity/speed, we update the 'family_members' table which acts as the display source.
    await _client
        .from('family_members')
        .update({'name': newName, 'color': newColorHex})
        .eq('id', memberId);
  }

  // Delete a Virtual Member (Child)
  Future<void> deleteMember(String memberId) async {
    // Security check: RLS policies on the server will prevent deleting a Real User
    // if we set them up correctly, but we should also check here or handle the error.
    await _client.from('family_members').delete().eq('id', memberId);
  }
}

final memberRepositoryProvider = Provider(
  (ref) => MemberRepository(Supabase.instance.client),
);

final membersStreamProvider = StreamProvider<List<FamilyMember>>((ref) {
  return ref.watch(memberRepositoryProvider).getMembers();
});
