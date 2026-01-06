import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
// Import your actual repository file
import '../../../calendar/data/calendar_repository.dart';

class CalendarSummaryWidget extends ConsumerStatefulWidget {
  const CalendarSummaryWidget({super.key});

  @override
  ConsumerState<CalendarSummaryWidget> createState() =>
      _CalendarSummaryWidgetState();
}

class _CalendarSummaryWidgetState extends ConsumerState<CalendarSummaryWidget> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // 1. Use the correct provider name from your file
    final eventsAsync = ref.watch(eventsStreamProvider);

    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Error loading events')),
        data: (events) {
          // 2. Convert FamilyEvent to Syncfusion Source
          final dataSource = _DashboardDataSource(events);

          // 3. Filter events for the list below
          final selectedEvents = events.where((e) {
            return e.startTime.year == _selectedDate.year &&
                e.startTime.month == _selectedDate.month &&
                e.startTime.day == _selectedDate.day;
          }).toList();

          return Column(
            children: [
              // --- MINI CALENDAR (Top Half) ---
              SizedBox(
                height: 250,
                child: SfCalendar(
                  view: CalendarView.month,
                  dataSource: dataSource,
                  backgroundColor: Colors.transparent,
                  cellBorderColor: Colors.transparent,
                  headerHeight: 40,
                  headerStyle: const CalendarHeaderStyle(
                    textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  viewHeaderStyle: const ViewHeaderStyle(
                    dayTextStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  monthViewSettings: const MonthViewSettings(
                    appointmentDisplayMode:
                        MonthAppointmentDisplayMode.indicator,
                    showAgenda: false,
                    navigationDirection: MonthNavigationDirection.horizontal,
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

                  onSelectionChanged: (CalendarSelectionDetails details) {
                    if (details.date != null) {
                      setState(() {
                        _selectedDate = details.date!;
                      });
                    }
                  },
                ),
              ),

              const Divider(height: 1),

              // --- EVENT LIST (Bottom Half) ---
              Expanded(
                child: selectedEvents.isEmpty
                    ? Center(
                        child: Text(
                          'No plans for ${_selectedDate.day}/${_selectedDate.month}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8),
                        itemCount: selectedEvents.length,
                        itemBuilder: (context, index) {
                          final event = selectedEvents[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                left: BorderSide(
                                  // Simple color logic
                                  color: Colors.blue,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: ListTile(
                              visualDensity: VisualDensity.compact,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                              title: Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                // Use 'startTime' from your FamilyEvent class
                                "${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}",
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- SYNCFUSION DATA SOURCE BRIDGE ---
class _DashboardDataSource extends CalendarDataSource {
  // Use FamilyEvent here
  _DashboardDataSource(List<FamilyEvent> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    // Map 'startTime' from FamilyEvent
    return (appointments![index] as FamilyEvent).startTime;
  }

  @override
  DateTime getEndTime(int index) {
    // Map 'endTime' from FamilyEvent
    return (appointments![index] as FamilyEvent).endTime;
  }

  @override
  String getSubject(int index) {
    return (appointments![index] as FamilyEvent).title;
  }

  @override
  Color getColor(int index) {
    return Colors.blue;
  }
}
