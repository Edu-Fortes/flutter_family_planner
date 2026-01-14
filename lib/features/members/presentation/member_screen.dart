import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/data/profile_repository.dart';
import '../data/member_repository.dart';
import 'edit_family_member_screen.dart';
import '../../profile/presentation/edit_profile_screen.dart';

class MemberScreen extends ConsumerWidget {
  const MemberScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. WATCH THE UNIFIED MIXER PROVIDER
    final membersAsync = ref.watch(allMembersProvider); // <--- MIXER
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Membros da Família')),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text('Nenhum membro encontrado.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final member = members[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: member.avatarUrl != null
                      ? NetworkImage(member.avatarUrl!)
                      : null,
                  backgroundColor: Color(member.colorValue),
                  child: member.avatarUrl == null
                      ? Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  member.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  member.isVirtual
                      ? 'Criança (Conta Virtual)'
                      : 'Usuário do App',
                  style: TextStyle(
                    color: member.isVirtual ? Colors.orange : Colors.grey,
                  ),
                ),
                trailing: const Icon(Icons.edit, size: 16, color: Colors.grey),

                // --- ROUTING LOGIC ---
                onTap: () {
                  final currentUserId =
                      Supabase.instance.client.auth.currentUser?.id;

                  // 1. IF CHILD -> EditFamilyMemberScreen
                  if (member.isVirtual) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditFamilyMemberScreen(member: member),
                      ),
                    );
                  }
                  // 2. IF ME -> EditProfileScreen
                  else if (member.profileId == currentUserId) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  }
                  // 3. IF OTHER ADULT -> Block
                  else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Você só pode editar seu próprio perfil.',
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: profileAsync.when(
        data: (profile) => profile?.role == 'admin'
            ? FloatingActionButton.extended(
                onPressed: () => _showAddMemberDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Criança'),
              )
            : null,
        loading: () => null,
        error: (_, _) => null,
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    Color selectedColor = Colors.orange;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Adicionar Criança'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  BlockPicker(
                    pickerColor: selectedColor,
                    availableColors: const [
                      Colors.orange,
                      Colors.pink,
                      Colors.purple,
                      Colors.teal,
                      Colors.green,
                      Colors.blueAccent,
                      Colors.indigo,
                      Colors.brown,
                    ],
                    onColorChanged: (color) =>
                        setState(() => selectedColor = color),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) return;
                  final colorInt = selectedColor.toARGB32();
                  final hex =
                      '#${colorInt.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

                  await ref
                      .read(memberRepositoryProvider)
                      .addVirtualMember(nameController.text.trim(), hex);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Adicionar'),
              ),
            ],
          );
        },
      ),
    );
  }
}
