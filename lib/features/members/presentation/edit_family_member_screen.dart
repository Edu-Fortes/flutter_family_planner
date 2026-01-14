import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../data/member_repository.dart';

class EditFamilyMemberScreen extends ConsumerStatefulWidget {
  final FamilyMember member;
  const EditFamilyMemberScreen({super.key, required this.member});

  @override
  ConsumerState<EditFamilyMemberScreen> createState() =>
      _EditFamilyMemberScreenState();
}

class _EditFamilyMemberScreenState
    extends ConsumerState<EditFamilyMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedColor;
  String? _avatarUrl;
  File? _localImageFile;
  bool _isLoading = false;

  final List<String> _colorOptions = [
    '#F44336',
    '#E91E63',
    '#9C27B0',
    '#2196F3',
    '#009688',
    '#4CAF50',
    '#FFC107',
    '#FF5722',
    '#607D8B',
    '#795548',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _selectedColor = widget.member.color.startsWith('#')
        ? widget.member.color
        : '#${widget.member.color.replaceAll('0xff', '')}';
    _avatarUrl = widget.member.avatarUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _localImageFile = File(pickedFile.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(memberRepositoryProvider);

      // 1. Upload new image if selected
      if (_localImageFile != null) {
        _avatarUrl = await repo.uploadMemberAvatar(
          _localImageFile!,
          widget.member.id,
        );
      }

      // 2. Update Record
      await repo.updateVirtualMember(
        memberId: widget.member.id,
        name: _nameController.text.trim(),
        color: _selectedColor,
        avatarUrl: _avatarUrl,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Membro?'),
        content: Text('Tem certeza que deseja excluir ${widget.member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(memberRepositoryProvider).deleteMember(widget.member.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro: $e')));
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color hexToColor(String code) {
      try {
        return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
      } catch (_) {
        return Colors.orange;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Criança'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _isLoading ? null : _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: hexToColor(
                    _selectedColor,
                  ).withValues(alpha: 0.2),
                  backgroundImage: _localImageFile != null
                      ? FileImage(_localImageFile!)
                      : (_avatarUrl != null ? NetworkImage(_avatarUrl!) : null)
                            as ImageProvider?,
                  child: (_localImageFile == null && _avatarUrl == null)
                      ? Icon(
                          Icons.camera_alt,
                          size: 30,
                          color: hexToColor(_selectedColor),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                children: _colorOptions.map((hex) {
                  final isSelected = _selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: hexToColor(hex),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
