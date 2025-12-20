import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Add intl package to pubspec if missing
import '../../members/data/member_repository.dart';
import '../data/calendar_repository.dart';

class AddEventDialog extends ConsumerStatefulWidget {
  const AddEventDialog({super.key});

  @override
  ConsumerState<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends ConsumerState<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  // Default: Today, next full hour
  late DateTime _startDate;
  late DateTime _endDate;

  String? _selectedMemberId;
  bool _isAllDay = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
    _endDate = _startDate.add(const Duration(hours: 1));
  }

  @override
  Widget build(BuildContext context) {
    // 1. Fetch the Family Members for the dropdown
    final membersAsync = ref.watch(membersStreamProvider);

    return AlertDialog(
      title: const Text('Add Family Event'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TITLE INPUT
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  hintText: 'e.g., Soccer Practice',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 16),

              // MEMBER SELECTOR (Who is this for?)
              membersAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text('Error loading members: $err'),
                data: (members) {
                  // Auto-select the first member (or the current user) if empty
                  if (_selectedMemberId == null && members.isNotEmpty) {
                    // Try to match current user's profile ID if possible, else first
                    // For now, we default to the first one in the list
                    _selectedMemberId = members.first.id;
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedMemberId,
                    decoration: const InputDecoration(
                      labelText: 'Assign To',
                      border: OutlineInputBorder(),
                    ),
                    items: members.map((member) {
                      return DropdownMenuItem(
                        value: member.id,
                        child: Row(
                          children: [
                            // Color Dot
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(member.colorValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(member.name),
                            if (member.isChild)
                              const Text(
                                ' (Child)',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedMemberId = val),
                  );
                },
              ),
              const SizedBox(height: 16),

              // DATE & TIME PICKERS
              _buildDateTimeRow(
                label: 'Starts',
                date: _startDate,
                onChanged: (newDate) => setState(() {
                  _startDate = newDate;
                  // Auto-adjust end time if it becomes before start time
                  if (_endDate.isBefore(_startDate)) {
                    _endDate = _startDate.add(const Duration(hours: 1));
                  }
                }),
              ),
              const SizedBox(height: 8),
              _buildDateTimeRow(
                label: 'Ends',
                date: _endDate,
                onChanged: (newDate) => setState(() => _endDate = newDate),
              ),

              // ALL DAY TOGGLE
              SwitchListTile(
                title: const Text('All Day Event'),
                value: _isAllDay,
                onChanged: (val) => setState(() => _isAllDay = val),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveEvent, child: const Text('Save Event')),
      ],
    );
  }

  // Helper widget to pick date/time
  Widget _buildDateTimeRow({
    required String label,
    required DateTime date,
    required Function(DateTime) onChanged,
  }) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              // Date Picker Button
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    final newDateTime = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      date.hour,
                      date.minute,
                    );
                    onChanged(newDateTime);
                  }
                },
                child: Text(dateFormat.format(date)),
              ),
              // Time Picker Button (Hidden if All Day)
              if (!_isAllDay)
                TextButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(date),
                    );
                    if (picked != null) {
                      final newDateTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        picked.hour,
                        picked.minute,
                      );
                      onChanged(newDateTime);
                    }
                  },
                  child: Text(timeFormat.format(date)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate() || _selectedMemberId == null) return;

    final repo = ref.read(calendarRepositoryProvider);

    final newEvent = FamilyEvent(
      id: '', // Generated by DB
      title: _titleController.text,
      startTime: _startDate,
      endTime: _endDate,
      isAllDay: _isAllDay,
      assignedToMemberId: _selectedMemberId,
    );

    try {
      await repo.addEvent(newEvent);
      if (mounted) Navigator.pop(context); // Close dialog on success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
