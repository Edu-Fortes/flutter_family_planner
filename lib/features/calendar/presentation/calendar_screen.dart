import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../members/data/member_repository.dart';
import '../data/calendar_repository.dart';
import 'add_event_dialog.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch BOTH streams
    final eventsAsync = ref.watch(eventsStreamProvider);
    final membersAsync = ref.watch(membersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      // 2. We only show the calendar if BOTH loaded successfully
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (events) {
          return membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (members) {
              // 3. Create the DataSource with BOTH lists
              return SfCalendar(
                view: CalendarView.month,
                dataSource: _FamilyDataSource(events, members),
                monthViewSettings: const MonthViewSettings(
                  showAgenda: true,
                  appointmentDisplayMode:
                      MonthAppointmentDisplayMode.appointment,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const AddEventDialog());
  }
}

// 4. Custom Data Source to Merge Logic
class _FamilyDataSource extends CalendarDataSource {
  final List<FamilyMember> members;

  _FamilyDataSource(List<FamilyEvent> events, this.members) {
    appointments = events;
  }

  @override
  DateTime getStartTime(int index) {
    return (appointments![index] as FamilyEvent).startTime;
  }

  @override
  DateTime getEndTime(int index) {
    return (appointments![index] as FamilyEvent).endTime;
  }

  @override
  String getSubject(int index) {
    return (appointments![index] as FamilyEvent).title;
  }

  @override
  Color getColor(int index) {
    final event = appointments![index] as FamilyEvent;

    // LOOKUP: Find the member assigned to this event
    if (event.assignedToMemberId != null) {
      final member = members.firstWhere(
        (m) => m.id == event.assignedToMemberId,
        orElse: () => members.first, // Fallback
      );
      return Color(member.colorValue);
    }

    return Colors.grey; // Fallback if unassigned
  }
}
