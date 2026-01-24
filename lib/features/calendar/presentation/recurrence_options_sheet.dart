import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class RecurrenceOptionsSheet extends StatefulWidget {
  final DateTime startDate;
  final String? initialRule;
  final Function(String?) onRuleChanged;

  const RecurrenceOptionsSheet({
    super.key,
    required this.startDate,
    this.initialRule,
    required this.onRuleChanged,
  });

  @override
  State<RecurrenceOptionsSheet> createState() => _RecurrenceOptionsSheetState();
}

class _RecurrenceOptionsSheetState extends State<RecurrenceOptionsSheet> {
  RecurrenceType _recurrenceType = RecurrenceType.daily;
  int _interval = 1;
  RecurrenceRange _recurrenceRange = RecurrenceRange.noEndDate;
  DateTime? _endDate;
  int _occurrenceCount = 10;

  @override
  void initState() {
    super.initState();
  }

  // --- HELPER: Map DateTime weekday to Syncfusion WeekDays ---
  WeekDays _getWeekday(DateTime date) {
    switch (date.weekday) {
      case 1:
        return WeekDays.monday;
      case 2:
        return WeekDays.tuesday;
      case 3:
        return WeekDays.wednesday;
      case 4:
        return WeekDays.thursday;
      case 5:
        return WeekDays.friday;
      case 6:
        return WeekDays.saturday;
      case 7:
        return WeekDays.sunday;
      default:
        return WeekDays.monday;
    }
  }

  void _generateAndSave() {
    // 1. Handle Weekly Logic explicitly
    List<WeekDays> selectedWeekDays = [];
    if (_recurrenceType == RecurrenceType.weekly) {
      // Default to the start date's day (e.g., if event starts on Monday, repeat every Monday)
      selectedWeekDays = [_getWeekday(widget.startDate)];
    }

    final properties = RecurrenceProperties(
      startDate: widget.startDate,
      recurrenceType: _recurrenceType,
      recurrenceRange: _recurrenceRange,
      interval: _interval,
      recurrenceCount: _occurrenceCount,
      endDate: _endDate,
      weekDays: selectedWeekDays, // <--- CRITICAL FIX
    );

    final rRule = SfCalendar.generateRRule(
      properties,
      widget.startDate,
      widget.startDate.add(const Duration(hours: 1)),
    );

    widget.onRuleChanged(rRule);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repetição'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _generateAndSave,
            child: const Text(
              'Concluir',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. FREQUENCY
          const Text(
            'Frequência',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          DropdownButtonFormField<RecurrenceType>(
            initialValue: _recurrenceType,
            items: const [
              DropdownMenuItem(
                value: RecurrenceType.daily,
                child: Text('Diariamente'),
              ),
              DropdownMenuItem(
                value: RecurrenceType.weekly,
                child: Text('Semanalmente'),
              ),
              DropdownMenuItem(
                value: RecurrenceType.monthly,
                child: Text('Mensalmente'),
              ),
              DropdownMenuItem(
                value: RecurrenceType.yearly,
                child: Text('Anualmente'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _recurrenceType = val);
            },
          ),
          const SizedBox(height: 20),

          // 2. INTERVAL
          const Text(
            'Intervalo',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          Row(
            children: [
              const Text('A cada '),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _interval > 1
                    ? () => setState(() => _interval--)
                    : null,
              ),
              Text(
                '$_interval',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _interval++),
              ),
              Text(
                _recurrenceType == RecurrenceType.daily
                    ? ' dias'
                    : _recurrenceType == RecurrenceType.weekly
                    ? ' semanas'
                    : _recurrenceType == RecurrenceType.monthly
                    ? ' meses'
                    : ' anos',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. END DATE
          const Text(
            'Termina em',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          DropdownButtonFormField<RecurrenceRange>(
            initialValue: _recurrenceRange,
            items: const [
              DropdownMenuItem(
                value: RecurrenceRange.noEndDate,
                child: Text('Nunca'),
              ),
              DropdownMenuItem(
                value: RecurrenceRange.endDate,
                child: Text('Em uma data específica'),
              ),
              DropdownMenuItem(
                value: RecurrenceRange.count,
                child: Text('Após X ocorrências'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _recurrenceRange = val);
            },
          ),

          if (_recurrenceRange == RecurrenceRange.endDate)
            ListTile(
              title: Text(
                _endDate == null
                    ? 'Selecionar Data'
                    : 'Até: ${_endDate.toString().split(' ')[0]}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: widget.startDate.add(const Duration(days: 7)),
                  firstDate: widget.startDate,
                  lastDate: DateTime(2040),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
            ),

          if (_recurrenceRange == RecurrenceRange.count)
            Row(
              children: [
                const Text('Ocorrências: '),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _occurrenceCount > 1
                      ? () => setState(() => _occurrenceCount--)
                      : null,
                ),
                Text('$_occurrenceCount', style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _occurrenceCount++),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
