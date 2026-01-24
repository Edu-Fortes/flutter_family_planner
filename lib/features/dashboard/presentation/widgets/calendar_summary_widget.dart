import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';

import '../../../calendar/data/calendar_repository.dart';
import '../../../members/data/member_repository.dart';

class CalendarSummaryWidget extends ConsumerStatefulWidget {
  const CalendarSummaryWidget({super.key});

  @override
  ConsumerState<CalendarSummaryWidget> createState() =>
      _CalendarSummaryWidgetState();
}

class _CalendarSummaryWidgetState extends ConsumerState<CalendarSummaryWidget> {
  final CalendarController _calendarController = CalendarController();
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _calendarController.selectedDate = DateTime.now();
    _scheduleMidnightUpdate();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    _calendarController.dispose();
    super.dispose();
  }

  void _scheduleMidnightUpdate() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final duration = tomorrow.difference(now) + const Duration(seconds: 1);

    _midnightTimer = Timer(duration, () {
      if (mounted) {
        setState(() {
          final newNow = DateTime.now();
          _calendarController.selectedDate = newNow;
          _calendarController.displayDate = newNow;
        });
        _scheduleMidnightUpdate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsStreamProvider);
    final membersAsync = ref.watch(allMembersProvider);

    return Card(
      elevation: 0,
      color: Colors.transparent,
      margin: EdgeInsets.zero,
      child: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Erro ao carregar agenda')),
        data: (events) {
          final members = membersAsync.value ?? [];

          return SfCalendar(
            controller: _calendarController,
            view: CalendarView.month,
            dataSource: _DashboardDataSource(events, members),

            // Style
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
            selectionDecoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            todayHighlightColor: Colors.orange,

            monthViewSettings: const MonthViewSettings(
              appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
              showAgenda: true,
              agendaViewHeight: 380,
              agendaItemHeight: 60,
              agendaStyle: AgendaStyle(
                backgroundColor: Colors.transparent,
                dateTextStyle: TextStyle(color: Colors.grey, fontSize: 12),
                dayTextStyle: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            // --- 🛠️ FIXED BUILDER ---
            appointmentBuilder:
                (BuildContext context, CalendarAppointmentDetails details) {
                  if (details.appointments.isEmpty) return const SizedBox();

                  // 1. SAFE TYPE CHECKING
                  // Syncfusion sends 'Appointment' for recurring instances,
                  // and 'FamilyEvent' for normal ones (sometimes).
                  final dynamic rawAppt = details.appointments.first;
                  FamilyEvent event;

                  if (rawAppt is FamilyEvent) {
                    event = rawAppt;
                  } else if (rawAppt is Appointment) {
                    // It's a recurring instance!
                    // We reconstruct a temporary FamilyEvent using the data.
                    // We retrieved 'assignedToMemberId' from the 'notes' field (see DataSource).
                    event = FamilyEvent(
                      id: rawAppt.id?.toString() ?? 'recurrence',
                      title: rawAppt.subject,
                      startTime: rawAppt.startTime,
                      endTime: rawAppt.endTime,
                      isAllDay: rawAppt.isAllDay,
                      assignedToMemberId: rawAppt.notes, // <--- MAGIC LINK
                      recurrenceRule: rawAppt.recurrenceRule,
                    );
                  } else {
                    return const SizedBox();
                  }

                  // 2. Find Member
                  FamilyMember? member;
                  if (event.assignedToMemberId != null) {
                    try {
                      member = members.firstWhere(
                        (m) =>
                            m.id == event.assignedToMemberId ||
                            m.profileId == event.assignedToMemberId,
                      );
                    } catch (_) {}
                  }

                  final color = member != null
                      ? Color(member.colorValue)
                      : Theme.of(context).primaryColor;

                  // 3. Render
                  if (details.bounds.width < 100) {
                    return Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(left: BorderSide(color: color, width: 4)),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(bottom: 4, right: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 45,
                          child: event.isAllDay
                              ? const Center(
                                  child: Text(
                                    'Dia\nTodo',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      height: 1.1,
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'HH:mm',
                                      ).format(event.startTime),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(event.endTime),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(width: 8),
                        if (member != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: color.withValues(alpha: 0.2),
                              backgroundImage: member.avatarUrl != null
                                  ? NetworkImage(member.avatarUrl!)
                                  : null,
                              child: member.avatarUrl == null
                                  ? Text(
                                      member.name.isNotEmpty
                                          ? member.name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                },
          );
        },
      ),
    );
  }
}

// --- DATA SOURCE (With Fixes) ---
class _DashboardDataSource extends CalendarDataSource {
  final List<FamilyMember> members;

  _DashboardDataSource(List<FamilyEvent> source, this.members) {
    appointments = source;
  }

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

  // 🛠️ CRITICAL FIX 1: Pass custom data via 'notes'
  @override
  String? getNotes(int index) {
    return (appointments![index] as FamilyEvent).assignedToMemberId;
  }

  // 🛠️ CRITICAL FIX 2: Defensive Recurrence Rule
  @override
  String? getRecurrenceRule(int index) {
    final rule = (appointments![index] as FamilyEvent).recurrenceRule;
    if (rule != null &&
        rule.contains('FREQ=WEEKLY') &&
        !rule.contains('BYDAY')) {
      return null; // Ignore invalid rules
    }
    return rule;
  }

  // 🛠️ CRITICAL FIX 3: Parse Exception Dates
  @override
  List<DateTime>? getRecurrenceExceptionDates(int index) {
    final event = appointments![index] as FamilyEvent;
    if (event.exceptionDates == null || event.exceptionDates!.isEmpty) {
      return null;
    }
    return event.exceptionDates!
        .split(',')
        .map((dateString) => DateTime.parse(dateString))
        .toList();
  }

  @override
  Color getColor(int index) {
    final event = appointments![index] as FamilyEvent;
    if (event.assignedToMemberId == null) return Colors.blueGrey;
    try {
      final member = members.firstWhere(
        (m) =>
            m.id == event.assignedToMemberId ||
            m.profileId == event.assignedToMemberId,
      );
      return Color(member.colorValue);
    } catch (e) {
      return Colors.blue;
    }
  }
}
