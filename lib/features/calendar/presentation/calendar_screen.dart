import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../members/data/member_repository.dart';
import '../data/calendar_repository.dart';
import 'add_event_dialog.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late _FamilyDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _dataSource = _FamilyDataSource([], []);
  }

  /// 📐 HELPER: Round time to nearest 5 minutes
  DateTime _roundToNearestFive(DateTime date) {
    final int delta = date.minute % 5;
    final int round = delta >= 3 ? (5 - delta) : -delta;
    return date
        .add(Duration(minutes: round))
        .copyWith(second: 0, millisecond: 0);
  }

  /// 🔒 HANDLE DRAG & DROP SAVE
  Future<void> _handleDragEnd(AppointmentDragEndDetails details) async {
    final appointment = details.appointment;
    final droppingTime = details.droppingTime;

    if (appointment == null || droppingTime == null) return;
    if (appointment is! FamilyEvent) return;

    // 1. Round to 5 mins
    final newStartTime = _roundToNearestFive(droppingTime);

    // 2. Calculate End Time
    final originalEvent = appointment;
    final duration = originalEvent.endTime.difference(originalEvent.startTime);
    final newEndTime = newStartTime.add(duration);

    await _saveUpdate(originalEvent, newStartTime, newEndTime);
  }

  /// 🔒 HANDLE RESIZE SAVE
  Future<void> _handleResizeEnd(AppointmentResizeEndDetails details) async {
    final appointment = details.appointment;
    final rawStartTime = details.startTime;
    final rawEndTime = details.endTime;

    if (appointment == null || rawStartTime == null || rawEndTime == null) {
      return;
    }

    if (appointment is! FamilyEvent) return;

    // 1. Round both times
    final newStartTime = _roundToNearestFive(rawStartTime);
    final newEndTime = _roundToNearestFive(rawEndTime);

    await _saveUpdate(appointment, newStartTime, newEndTime);
  }

  /// 💾 COMMON SAVE LOGIC
  Future<void> _saveUpdate(
    FamilyEvent original,
    DateTime start,
    DateTime end,
  ) async {
    // Prevent 0-minute events
    DateTime finalEnd = end;
    if (end.isAtSameMomentAs(start) || end.isBefore(start)) {
      finalEnd = start.add(const Duration(minutes: 5));
    }

    final updatedEvent = FamilyEvent(
      id: original.id,
      title: original.title,
      startTime: start,
      endTime: finalEnd,
      isAllDay: original.isAllDay,
      assignedToMemberId: original.assignedToMemberId,
    );

    try {
      await ref.read(calendarRepositoryProvider).updateEvent(updatedEvent);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento atualizado!'),
          duration: Duration(milliseconds: 500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsStreamProvider);
    final membersAsync = ref.watch(allMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planejamento Familiar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AddEventDialog(),
            ),
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (events) {
          return membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (members) {
              _dataSource.updateData(events, members);

              return SfCalendar(
                // REMOVED 'locale' parameter (Set this in main.dart instead)

                // 24H FORMAT SETTINGS
                timeSlotViewSettings: const TimeSlotViewSettings(
                  timeFormat: 'HH:mm',
                  timeIntervalHeight: 60,
                ),
                appointmentTimeTextFormat: 'HH:mm',

                view: CalendarView.month,
                showTodayButton: true,
                showNavigationArrow: true,
                dataSource: _dataSource,

                // INTERACTION
                allowDragAndDrop: true,
                allowAppointmentResize: true,
                dragAndDropSettings: const DragAndDropSettings(
                  allowNavigation: true,
                  showTimeIndicator: true,
                ),
                onDragEnd: _handleDragEnd,
                onAppointmentResizeEnd: _handleResizeEnd,

                // VIEWS
                monthViewSettings: const MonthViewSettings(
                  showAgenda: true,
                  appointmentDisplayMode:
                      MonthAppointmentDisplayMode.appointment,
                  showTrailingAndLeadingDates: false,
                  dayFormat: 'EEE',
                ),
                allowedViews: const [
                  CalendarView.day,
                  CalendarView.week,
                  CalendarView.month,
                ],

                onTap: (CalendarTapDetails details) {
                  if (details.targetElement == CalendarElement.appointment &&
                      details.appointments != null &&
                      details.appointments!.isNotEmpty) {
                    final firstAppt = details.appointments!.first;
                    if (firstAppt is FamilyEvent) {
                      showDialog(
                        context: context,
                        builder: (_) => AddEventDialog(eventToEdit: firstAppt),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------
// 🛠️ DATA SOURCE
// ---------------------------------------------------------
class _FamilyDataSource extends CalendarDataSource {
  List<FamilyMember> members;

  _FamilyDataSource(List<FamilyEvent> events, this.members) {
    appointments = events;
  }

  void updateData(List<FamilyEvent> events, List<FamilyMember> newMembers) {
    appointments = events;
    members = newMembers;
    notifyListeners(CalendarDataSourceAction.reset, events);
  }

  @override
  FamilyEvent convertAppointmentToObject(
    Object? customData,
    Appointment appointment,
  ) {
    if (customData is FamilyEvent) return customData;
    return FamilyEvent(
      id: 'temp',
      title: appointment.subject,
      startTime: appointment.startTime,
      endTime: appointment.endTime,
      isAllDay: appointment.isAllDay,
    );
  }

  @override
  Object getId(int index) => (appointments![index] as FamilyEvent).id;

  @override
  DateTime getStartTime(int index) =>
      (appointments![index] as FamilyEvent).startTime;

  @override
  DateTime getEndTime(int index) =>
      (appointments![index] as FamilyEvent).endTime;

  @override
  String getSubject(int index) => (appointments![index] as FamilyEvent).title;

  @override
  bool isAllDay(int index) => (appointments![index] as FamilyEvent).isAllDay;

  @override
  String? getRecurrenceRule(int index) {
    final event = appointments![index] as FamilyEvent;
    final rule = event.recurrenceRule;

    if (rule == null) return null;

    // CRITICAL FIX: Block invalid weekly rules
    if (rule.contains('FREQ=WEEKLY') && !rule.contains('BYDAY')) {
      return null;
    }

    return rule;
  }

  @override
  List<DateTime>? getRecurrenceExceptionDates(int index) {
    final event = appointments![index] as FamilyEvent;
    if (event.exceptionDates == null || event.exceptionDates!.isEmpty) {
      return null;
    }
    // Parse the comma-separated string back to DateTime list
    return event.exceptionDates!
        .split(',')
        .map((dateString) => DateTime.parse(dateString))
        .toList();
  }

  @override
  Color getColor(int index) {
    final event = appointments![index] as FamilyEvent;
    if (event.assignedToMemberId != null) {
      try {
        final member = members.firstWhere(
          (m) => m.id == event.assignedToMemberId,
        );
        return Color(member.colorValue);
      } catch (e) {
        return Colors.grey;
      }
    }
    return Colors.grey;
  }
}
