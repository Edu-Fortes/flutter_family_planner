import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../members/data/member_repository.dart';
import '../data/calendar_repository.dart';
import 'recurrence_options_sheet.dart'; // <--- Import this

class AddEventDialog extends ConsumerStatefulWidget {
  final FamilyEvent? eventToEdit;

  const AddEventDialog({super.key, this.eventToEdit});

  @override
  ConsumerState<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends ConsumerState<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;

  late DateTime _startDate;
  late DateTime _endDate;
  String? _selectedMemberId;
  bool _isAllDay = false;
  String? _recurrenceRule; // <--- State for RRule

  @override
  void initState() {
    super.initState();
    final editEvent = widget.eventToEdit;

    if (editEvent != null) {
      // EDIT MODE
      _titleController = TextEditingController(text: editEvent.title);
      _startDate = editEvent.startTime;
      _endDate = editEvent.endTime;
      _isAllDay = editEvent.isAllDay;
      _selectedMemberId = editEvent.assignedToMemberId;
      _recurrenceRule = editEvent.recurrenceRule; // <--- Load existing rule
    } else {
      // ADD MODE
      _titleController = TextEditingController();
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
      _endDate = _startDate.add(const Duration(hours: 1));
      _recurrenceRule = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(allMembersProvider);
    final isEditing = widget.eventToEdit != null;

    final dateFormat = DateFormat('dd MMM yyyy');
    final dateTimeFormat = DateFormat('dd MMM, HH:mm');
    final displayFormat = _isAllDay ? dateFormat : dateTimeFormat;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Evento' : 'Adicionar Evento'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (val) => val!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),

              membersAsync.when(
                data: (members) {
                  if (_selectedMemberId == null && members.isNotEmpty) {
                    _selectedMemberId = members.first.id;
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedMemberId,
                    decoration: const InputDecoration(labelText: 'Atribuir a'),
                    items: members
                        .map(
                          (m) => DropdownMenuItem(
                            value: m.id,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Color(m.colorValue),
                                  radius: 6,
                                ),
                                const SizedBox(width: 8),
                                Text(m.name),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedMemberId = val),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Erro ao carregar membros'),
              ),
              const SizedBox(height: 16),

              ListTile(
                title: Text("Início: ${displayFormat.format(_startDate)}"),
                trailing: const Icon(Icons.calendar_today, size: 16),
                onTap: () => _pickDate(true),
              ),
              ListTile(
                title: Text("Fim: ${displayFormat.format(_endDate)}"),
                trailing: const Icon(Icons.calendar_today, size: 16),
                onTap: () => _pickDate(false),
              ),

              SwitchListTile(
                title: const Text('Dia Inteiro'),
                value: _isAllDay,
                onChanged: (val) => setState(() => _isAllDay = val),
                contentPadding: EdgeInsets.zero,
              ),

              // --- RECURRENCE OPTION ---
              ListTile(
                leading: const Icon(Icons.loop),
                title: const Text('Repetir'),
                subtitle: Text(
                  (_recurrenceRule == null || _recurrenceRule!.isEmpty)
                      ? 'Nunca'
                      : 'Regra Personalizada', // You can parse this to "Weekly" etc later
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true, // Need full screen for editor
                    builder: (_) => RecurrenceOptionsSheet(
                      startDate: _startDate,
                      initialRule: _recurrenceRule,
                      onRuleChanged: (rule) {
                        setState(() => _recurrenceRule = rule);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (isEditing)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: _delete,
            child: const Text('Excluir'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEditing ? 'Atualizar' : 'Salvar'),
        ),
      ],
    );
  }

  // ... _pickDate function remains the same ...
  Future<void> _pickDate(bool isStart) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null && mounted) {
      if (_isAllDay) {
        setState(() {
          final newDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            isStart ? _startDate.hour : _endDate.hour,
            isStart ? _startDate.minute : _endDate.minute,
          );
          if (isStart) {
            _startDate = newDate;
          } else {
            _endDate = newDate;
          }
        });
      } else {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _endDate),
        );
        if (pickedTime != null && mounted) {
          setState(() {
            final newDate = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            if (isStart) {
              _startDate = newDate;
            } else {
              _endDate = newDate;
            }
          });
        }
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedMemberId == null) return;

    final repo = ref.read(calendarRepositoryProvider);

    final event = FamilyEvent(
      id: widget.eventToEdit?.id ?? '',
      title: _titleController.text,
      startTime: _startDate,
      endTime: _endDate,
      assignedToMemberId: _selectedMemberId,
      isAllDay: _isAllDay,
      recurrenceRule: _recurrenceRule, // <--- SAVE RULE
      exceptionDates: widget.eventToEdit?.exceptionDates, // Preserve exceptions
    );

    if (widget.eventToEdit != null) {
      await repo.updateEvent(event);
    } else {
      await repo.addEvent(event);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    // ... delete confirmation code (remains same) ...
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir evento?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(calendarRepositoryProvider)
          .deleteEvent(widget.eventToEdit!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}
