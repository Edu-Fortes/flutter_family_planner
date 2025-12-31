import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../data/invitation_repository.dart';

class InvitationScreen extends ConsumerWidget {
  const InvitationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationsAsync = ref.watch(invitationsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Convites')),
      body: invitationsAsync.when(
        data: (invitations) {
          if (invitations.isEmpty) {
            return const Center(child: Text('Nenhum convite criado ainda.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: invitations.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final invite = invitations[index];
              return ListTile(
                title: Text(
                  invite.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                ),
                subtitle: Text(
                  invite.isUsed ? 'Status: USADO' : 'Status: ATIVO',
                  style: TextStyle(
                    color: invite.isUsed ? Colors.red : Colors.green,
                  ),
                ),
                trailing: invite.isUsed
                    ? const Icon(Icons.check_circle, color: Colors.grey)
                    : IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          // Copy to clipboard logic could go here
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Código ${invite.code} pronto para compartilhar!',
                              ),
                            ),
                          );
                        },
                      ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Novo Código'),
        onPressed: () => _showAddDialog(context, ref),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    // Generate a random 4-digit suffix
    final random = Random().nextInt(9000) + 1000;
    final suggestedCode = 'FAMILIA-$random';
    final controller = TextEditingController(text: suggestedCode);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criar Convite'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Código do Convite',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(invitationRepositoryProvider)
                    .createInvitation(controller.text.trim());
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}
