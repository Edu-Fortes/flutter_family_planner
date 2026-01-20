import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../data/profile_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _fullNameController = TextEditingController();
  final _displayNameController = TextEditingController();

  // State
  String _selectedColor = '#2196F3';
  String? _avatarUrl;

  // WEB-SAFE IMAGE HANDLING
  XFile? _pickedFile;
  Uint8List? _pickedImageBytes;
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
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final profileAsync = ref.read(profileProvider);
    profileAsync.whenData((profile) {
      if (profile != null) {
        _fullNameController.text = profile.fullName ?? '';
        _displayNameController.text = profile.displayName ?? profile.username;
        setState(() {
          _selectedColor = profile.color;
          _avatarUrl = profile.avatarUrl;
        });
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _pickedFile = pickedFile;
        _pickedImageBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(profileRepositoryProvider);

      // 1. Upload Image (if changed)
      if (_pickedFile != null) {
        await repo.uploadAvatar(_pickedFile!);
      }

      // 2. Update Text Data
      await repo.updateProfile(
        fullName: _fullNameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        color: _selectedColor,
      );

      ref.invalidate(profileProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Perfil atualizado!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color hexToColor(String code) {
      try {
        return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
      } catch (_) {
        return Colors.blue;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Meu Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- AVATAR ---
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: hexToColor(
                    _selectedColor,
                  ).withValues(alpha: 0.2),
                  // PREVIEW: Use MemoryImage for local bytes, NetworkImage for URL
                  backgroundImage: _pickedImageBytes != null
                      ? MemoryImage(_pickedImageBytes!)
                      : (_avatarUrl != null ? NetworkImage(_avatarUrl!) : null)
                            as ImageProvider?,
                  child: (_pickedImageBytes == null && _avatarUrl == null)
                      ? Icon(
                          Icons.camera_alt,
                          size: 30,
                          color: hexToColor(_selectedColor),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Toque para alterar foto',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // --- FIELDS ---
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome de Exibição (Apelido)',
                  hintText: 'Como você aparecerá no calendário',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // --- COLORS ---
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sua Cor',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colorOptions.map((hex) {
                  final isSelected = _selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: hexToColor(hex),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // --- BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
