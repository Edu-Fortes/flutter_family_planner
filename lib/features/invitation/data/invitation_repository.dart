import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Invitation {
  final String id;
  final String code;
  final bool isUsed;
  final DateTime createdAt;

  Invitation({
    required this.id,
    required this.code,
    required this.isUsed,
    required this.createdAt,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'],
      code: json['code'],
      isUsed: json['is_used'] ?? false,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}

class InvitationRepository {
  final SupabaseClient _client;
  InvitationRepository(this._client);

  // Get list of invitations created by this admin
  Stream<List<Invitation>> getInvitations() {
    return _client
        .from('invitations')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((data) => data.map((e) => Invitation.fromJson(e)).toList());
  }

  // Generate a new random code
  Future<void> createInvitation(String code) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _client.from('invitations').insert({
      'code': code,
      'created_by': user.id,
    });
  }
}

final invitationRepositoryProvider = Provider((ref) {
  return InvitationRepository(Supabase.instance.client);
});

final invitationsStreamProvider = StreamProvider<List<Invitation>>((ref) {
  return ref.watch(invitationRepositoryProvider).getInvitations();
});
