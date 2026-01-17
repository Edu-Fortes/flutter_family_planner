import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';

import '../../../calendar/data/calendar_repository.dart';
import '../../../members/data/member_repository.dart'; //

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

  // Ensures the "Today" indicator updates correctly at midnight
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
    // 1. Fetch Data
    final eventsAsync = ref.watch(eventsStreamProvider);
    final membersAsync = ref.watch(allMembersProvider); // The Unified Mixer

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

            // --- AGENDA SETTINGS ---
            monthViewSettings: const MonthViewSettings(
              appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
              showAgenda: true,
              agendaViewHeight: 380, // Adjust based on your UI needs
              agendaItemHeight: 60, // Taller rows for avatars
              agendaStyle: AgendaStyle(
                backgroundColor: Colors.transparent,
                dateTextStyle: TextStyle(color: Colors.grey, fontSize: 12),
                dayTextStyle: TextStyle(
                  color: Colors.black, // Visible text
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            // --- THE MAGIC BUILDER ---
            appointmentBuilder:
                (BuildContext context, CalendarAppointmentDetails details) {
                  if (details.appointments.isEmpty) return const SizedBox();

                  final event = details.appointments.first as FamilyEvent;

                  // 1. Find Member (Simplified Logic thanks to 'allMembersProvider')
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

                  // 2. CHECK: Is this a Month Cell (Dot) or Agenda Row (Tile)?
                  // We use width as a heuristic. Grid cells are narrow (< 60px).
                  if (details.bounds.width < 100) {
                    // --- RENDER DOT (Month Grid) ---
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

                  // --- RENDER FULL ROW (Agenda List) ---
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
                    margin: const EdgeInsets.only(
                      bottom: 4,
                      right: 4,
                    ), // Small spacing
                    child: Row(
                      children: [
                        // A. Time Column
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

                        // B. Avatar
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

                        // C. Title
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

// --- DATA SOURCE ---
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

  @override
  Color getColor(int index) {
    // This color is used for the default indicators if the builder fails
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
