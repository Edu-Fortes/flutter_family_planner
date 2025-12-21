import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'edit_member_dialog.dart';
import '../../profile/data/profile_repository.dart';
import '../data/member_repository.dart';

class MemberScreen extends ConsumerWidget {
  const MemberScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersStreamProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Family Members')),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text('No members found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final member = members[index];

              // Helper to check if current user is admin
              // (We can get this from profileAsync.value or check locally)
              final isCurrentUserAdmin = profileAsync.value?.role == 'admin';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(member.colorValue),
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  member.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  member.isChild
                      ? 'Child (Virtual Account)'
                      : 'Full Member (App User)',
                  style: TextStyle(
                    color: member.isChild ? Colors.orange : Colors.grey,
                  ),
                ),
                trailing: const Icon(Icons.edit, size: 16, color: Colors.grey),
                // Open Edit Dialog
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => EditMemberDialog(
                      member: member,
                      isAdmin: isCurrentUserAdmin,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      // Only Admins see the Floating Action Button
      floatingActionButton: profileAsync.when(
        data: (profile) => profile?.role == 'admin'
            ? FloatingActionButton.extended(
                onPressed: () => _showAddMemberDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add Child'),
              )
            : null,
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    Color selectedColor = Colors.orange;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Family Member'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create a profile for a child or family member who does not have an email account.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g., Junior',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Assign Color:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // FIX: Removed custom layoutBuilder.
                  // The default layout is already a nice grid.
                  BlockPicker(
                    pickerColor: selectedColor,
                    availableColors: const [
                      Colors.orange,
                      Colors.pink,
                      Colors.purple,
                      Colors.teal,
                      Colors.green,
                      Colors.redAccent,
                      Colors.blueAccent,
                      Colors.indigo,
                      Colors.brown,
                      Colors.amber,
                    ],
                    // We remove the layoutBuilder entirely to avoid the type errors.
                    onColorChanged: (color) {
                      setState(() => selectedColor = color);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) return;

                  // FIX: Updated logic to convert color to Hex String safely
                  // We treat the integer value as unsigned to ensure correct hex string
                  final colorInt = selectedColor.value;
                  final hex =
                      '#${colorInt.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

                  await ref
                      .read(memberRepositoryProvider)
                      .addVirtualMember(nameController.text.trim(), hex);

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Add Member'),
              ),
            ],
          );
        },
      ),
    );
  }
}
