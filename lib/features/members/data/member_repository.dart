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
}

final memberRepositoryProvider = Provider(
  (ref) => MemberRepository(Supabase.instance.client),
);

final membersStreamProvider = StreamProvider<List<FamilyMember>>((ref) {
  return ref.watch(memberRepositoryProvider).getMembers();
});
