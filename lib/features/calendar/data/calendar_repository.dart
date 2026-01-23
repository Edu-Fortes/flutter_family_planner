import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FamilyEvent {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final String? assignedToMemberId;
  // --- NEW FIELDS ---
  final String? recurrenceRule;
  final String? exceptionDates;

  FamilyEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.assignedToMemberId,
    this.recurrenceRule,
    this.exceptionDates,
  });

  factory FamilyEvent.fromJson(Map<String, dynamic> json) {
    return FamilyEvent(
      id: json['id'],
      title: json['title'],
      startTime: DateTime.parse(json['start_time']).toLocal(),
      endTime: DateTime.parse(json['end_time']).toLocal(),
      isAllDay: json['is_all_day'] ?? false,
      assignedToMemberId: json['assigned_to'],
      recurrenceRule: json['recurrence_rule'], // <--- Map it
      exceptionDates: json['exception_dates'], // <--- Map it
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'is_all_day': isAllDay,
      'assigned_to': assignedToMemberId,
      'recurrence_rule': recurrenceRule, // <--- Send it
      'exception_dates': exceptionDates, // <--- Send it
    };
  }
}

class CalendarRepository {
  final SupabaseClient _client;
  CalendarRepository(this._client);

  Stream<List<FamilyEvent>> getEvents() {
    return _client
        .from('family_events')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => FamilyEvent.fromJson(json)).toList());
  }

  Future<void> addEvent(FamilyEvent event) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Must be logged in');

    final data = event.toJson();
    data['created_by'] = user.id;

    await _client.from('family_events').insert(data);
  }

  Future<void> updateEvent(FamilyEvent event) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Must be logged in');

    final data = event.toJson();
    await _client.from('family_events').update(data).eq('id', event.id);
  }

  Future<void> deleteEvent(String eventId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Must be logged in');

    await _client.from('family_events').delete().eq('id', eventId);
  }
}

final calendarRepositoryProvider = Provider(
  (ref) => CalendarRepository(Supabase.instance.client),
);
final eventsStreamProvider = StreamProvider(
  (ref) => ref.watch(calendarRepositoryProvider).getEvents(),
);
