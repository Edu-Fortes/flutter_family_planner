import 'dart:async'; // Required for Timer
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

// Import BOTH Repositories
import '../../../calendar/data/calendar_repository.dart';
import '../../../members/data/member_repository.dart';

class CalendarSummaryWidget extends ConsumerStatefulWidget {
  const CalendarSummaryWidget({super.key});

  @override
  ConsumerState<CalendarSummaryWidget> createState() =>
      _CalendarSummaryWidgetState();
}

class _CalendarSummaryWidgetState extends ConsumerState<CalendarSummaryWidget> {
  // 1. Controller to manipulate the calendar programmatically
  final CalendarController _calendarController = CalendarController();
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    // 2. Set initial selection to Today
    _calendarController.selectedDate = DateTime.now();

    // 3. Start the loop to update at midnight
    _scheduleMidnightUpdate();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    _calendarController.dispose();
    super.dispose();
  }

  // Calculates time until next midnight and sets a timer
  void _scheduleMidnightUpdate() {
    final now = DateTime.now();
    // Get the very beginning of "Tomorrow"
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    // Add 1 second buffer to ensure we are definitely in the new day
    final duration = tomorrow.difference(now) + const Duration(seconds: 1);

    _midnightTimer = Timer(duration, () {
      // 4. Update state when timer fires
      setState(() {
        final newNow = DateTime.now();
        _calendarController.selectedDate = newNow;
        _calendarController.displayDate =
            newNow; // Also moves the month view if needed
      });
      // Reschedule for the next night
      _scheduleMidnightUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch BOTH streams
    final eventsAsync = ref.watch(eventsStreamProvider);
    final membersAsync = ref.watch(allMembersProvider);

    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Error loading events')),
        data: (events) {
          final members = membersAsync.asData?.value ?? [];

          return SfCalendar(
            // 5. Attach the controller
            controller: _calendarController,

            view: CalendarView.month,
            dataSource: _DashboardDataSource(events, members),

            // Visual Styles
            backgroundColor: Colors.transparent,
            cellBorderColor: Colors.transparent,

            headerHeight: 40,
            headerStyle: const CalendarHeaderStyle(
              textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              backgroundColor: Colors.transparent,
            ),
            viewHeaderStyle: const ViewHeaderStyle(
              dayTextStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),

            appointmentTimeTextFormat: 'HH:mm',
            monthViewSettings: MonthViewSettings(
              appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
              showAgenda: true,
              agendaViewHeight: 380,
              agendaStyle: AgendaStyle(
                backgroundColor: Colors.transparent,
                appointmentTextStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                dayTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                dateTextStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),

            selectionDecoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            todayHighlightColor: Colors.orange,
          );
        },
      ),
    );
  }
}

// --- DATA SOURCE BRIDGE (Unchanged) ---
class _DashboardDataSource extends CalendarDataSource {
  final List<FamilyMember> members;

  _DashboardDataSource(List<FamilyEvent> source, this.members) {
    appointments = source;
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
  bool isAllDay(int index) {
    return (appointments![index] as FamilyEvent).isAllDay;
  }

  @override
  Color getColor(int index) {
    final event = appointments![index] as FamilyEvent;

    if (event.assignedToMemberId == null) return Colors.blueGrey;

    try {
      final member = members.firstWhere(
        (m) => m.id == event.assignedToMemberId,
      );
      return Color(member.colorValue);
    } catch (e) {
      return Colors.blue;
    }
  }
}
