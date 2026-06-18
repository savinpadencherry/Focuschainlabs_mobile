import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/meeting.dart';
import '../auth/google_auth_service.dart';
import 'calendar_service.dart';

/// Real meetings from the Google Calendar REST API, using the OAuth headers
/// from the signed-in Google session (calendar.events.readonly scope).
class GoogleCalendarService implements CalendarService {
  GoogleCalendarService({required GoogleAuthService auth, http.Client? client})
      : _auth = auth,
        _client = client ?? http.Client();

  final GoogleAuthService _auth;
  final http.Client _client;

  @override
  Future<List<Meeting>> events({
    required DateTime from,
    required DateTime to,
  }) async {
    final Map<String, String>? headers = await _auth.calendarAuthHeaders();
    if (headers == null) return <Meeting>[];

    final List<Meeting> meetings = <Meeting>[];
    String? pageToken;
    do {
      final Uri uri = Uri.https(
        'www.googleapis.com',
        '/calendar/v3/calendars/primary/events',
        <String, String>{
          'timeMin': from.toUtc().toIso8601String(),
          'timeMax': to.toUtc().toIso8601String(),
          'singleEvents': 'true',
          'orderBy': 'startTime',
          'maxResults': '100',
          if (pageToken != null) 'pageToken': pageToken,
        },
      );
      final http.Response res =
          await _client.get(uri, headers: headers).timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) break;

      final Map<String, dynamic> body = jsonDecode(res.body) as Map<String, dynamic>;
      final List<dynamic> items = body['items'] as List<dynamic>? ?? <dynamic>[];
      for (final dynamic raw in items) {
        final Meeting? m = _toMeeting(raw as Map<String, dynamic>);
        if (m != null) meetings.add(m);
      }
      pageToken = body['nextPageToken'] as String?;
    } while (pageToken != null);

    return meetings;
  }

  Meeting? _toMeeting(Map<String, dynamic> e) {
    final DateTime? start = _parseStamp(e['start']);
    if (start == null) return null;
    final DateTime end = _parseStamp(e['end']) ?? start.add(const Duration(minutes: 30));

    final List<String> attendees = ((e['attendees'] as List<dynamic>?) ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> a) => a['email']?.toString() ?? '')
        .where((String s) => s.isNotEmpty)
        .toList();

    final String title = e['summary']?.toString() ?? 'Meeting';
    return Meeting(
      id: e['id']?.toString() ?? title,
      title: title,
      clientName: _clientName(attendees, e['organizer'], title),
      start: start,
      durationMinutes: end.difference(start).inMinutes.clamp(5, 600),
      platform: _platform(e),
      attendees: attendees,
      captureEligible: _eligible(title, attendees, e['organizer']),
    );
  }

  DateTime? _parseStamp(dynamic node) {
    if (node is! Map) return null;
    final String? dt = node['dateTime']?.toString() ?? node['date']?.toString();
    return dt == null ? null : DateTime.tryParse(dt)?.toLocal();
  }

  String _platform(Map<String, dynamic> e) {
    if (e['hangoutLink'] != null || e['conferenceData'] != null) return 'Google Meet';
    final String loc = e['location']?.toString().toLowerCase() ?? '';
    if (loc.contains('zoom')) return 'Zoom';
    if (loc.contains('teams')) return 'Teams';
    return loc.isEmpty ? 'Calendar' : 'In person';
  }

  String _organizerDomain(dynamic organizer) {
    final String email = (organizer is Map ? organizer['email']?.toString() : '') ?? '';
    return email.contains('@') ? email.split('@').last : '';
  }

  /// Eligible when there's an external attendee and it isn't an internal sync.
  bool _eligible(String title, List<String> attendees, dynamic organizer) {
    final String t = title.toLowerCase();
    if (t.contains('standup') || t.contains('internal') || t.contains('1:1')) {
      return false;
    }
    final String orgDomain = _organizerDomain(organizer);
    return attendees.any((String a) =>
        a.contains('@') && a.split('@').last != orgDomain);
  }

  String _clientName(List<String> attendees, dynamic organizer, String title) {
    final String orgDomain = _organizerDomain(organizer);
    for (final String a in attendees) {
      if (a.contains('@') && a.split('@').last != orgDomain) {
        final String domain = a.split('@').last.split('.').first;
        return domain.isEmpty
            ? title
            : domain[0].toUpperCase() + domain.substring(1);
      }
    }
    return title;
  }
}
