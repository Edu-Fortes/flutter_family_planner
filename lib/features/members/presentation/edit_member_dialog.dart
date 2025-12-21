import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../data/member_repository.dart';

class EditMemberDialog extends ConsumerStatefulWidget {
  final FamilyMember member;
  final bool isAdmin; // We pass this to decide if Delete button is shown

  const EditMemberDialog({
    super.key,
    required this.member,
    required this.isAdmin,
  });

  @override
  ConsumerState<EditMemberDialog> createState() => _EditMemberDialogState();
}

class _EditMemberDialogState extends ConsumerState<EditMemberDialog> {
  late TextEditingController _nameController;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _selectedColor = Color(widget.member.colorValue);
  }

  @override
  Widget build(BuildContext context) {
    // Logic: You can delete if you are Admin AND the target is a Child (Virtual)
    final canDelete = widget.isAdmin && widget.member.isChild;

    return AlertDialog(
      title: const Text('Edit Member'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Member Color:'),
            const SizedBox(height: 8),
            BlockPicker(
              pickerColor: _selectedColor,
              availableColors: const [
                Colors.orange,
                Colors.pink,
                Colors.purple,
                Colors.deepPurple,
                Colors.indigo,
                Colors.blue,
                Colors.lightBlue,
                Colors.cyan,
                Colors.teal,
                Colors.green,
                Colors.lightGreen,
                Colors.lime,
                Colors.yellow,
                Colors.amber,
                Colors.brown,
                Colors.grey,
              ],
              onColorChanged: (color) => setState(() => _selectedColor = color),
            ),
          ],
        ),
      ),
      actions: [
        if (canDelete)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: _delete,
            child: const Text('Delete Member'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save Changes')),
      ],
    );
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) return;

    // Convert Color to Hex
    final colorInt = _selectedColor.value;
    final hex =
        '#${colorInt.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    await ref
        .read(memberRepositoryProvider)
        .updateMember(widget.member.id, _nameController.text.trim(), hex);

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Member?'),
        content: Text(
          'Delete ${widget.member.name}? This will remove them from all assigned events.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(memberRepositoryProvider).deleteMember(widget.member.id);
      if (mounted) Navigator.pop(context);
    }
  }
}
