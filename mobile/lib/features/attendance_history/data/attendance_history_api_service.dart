import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:qrollcall_mobile/core/config/app_config.dart';
import 'package:qrollcall_mobile/features/attendance_history/models/attendance_history_entry.dart';
import 'package:qrollcall_mobile/features/auth/data/firebase_auth_service.dart';

class AttendanceHistoryApiService {
  AttendanceHistoryApiService({
    required FirebaseAuthService firebaseAuthService,
    http.Client? client,
  })  : _firebaseAuthService = firebaseAuthService,
        _client = client ?? http.Client();

  final FirebaseAuthService _firebaseAuthService;
  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse('${AppConfig.apiBaseUrl}$path')
        .replace(queryParameters: queryParameters);
  }

  Future<List<AttendanceHistoryEntry>> fetchAttendanceHistory({
    int attendanceLimit = 200,
    int eventsLimit = 100,
  }) async {
    final idToken = await _firebaseAuthService.getIdToken(forceRefresh: true);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };

    final responses = await Future.wait([
      _client.get(
        _uri('/attendance', {'limit': '$attendanceLimit'}),
        headers: headers,
      ),
      _client.get(
        _uri('/events', {
          'limit': '$eventsLimit',
          'active_only': 'false',
        }),
        headers: headers,
      ),
    ]);

    final attendanceResponse = responses[0];
    final eventsResponse = responses[1];

    _ensureSuccess(attendanceResponse);
    _ensureSuccess(eventsResponse);

    final attendancePayload =
        jsonDecode(attendanceResponse.body) as Map<String, dynamic>;
    final eventsPayload = jsonDecode(eventsResponse.body) as Map<String, dynamic>;

    final attendanceItems =
        (attendancePayload['items'] as List<dynamic>? ?? const []);
    final eventItems = (eventsPayload['items'] as List<dynamic>? ?? const []);

    final eventMap = <int, Map<String, dynamic>>{};
    for (final raw in eventItems) {
      final item = raw as Map<String, dynamic>;
      final id = item['id'];
      if (id is int) {
        eventMap[id] = item;
      }
    }

    final entries = attendanceItems.map((raw) {
      final item = raw as Map<String, dynamic>;
      final eventId = item['event_id'] as int;
      final event = eventMap[eventId];

      return AttendanceHistoryEntry(
        id: item['id'] as int,
        eventId: eventId,
        eventName: (event?['name'] as String?)?.trim().isNotEmpty == true
            ? (event!['name'] as String).trim()
            : 'Event #$eventId',
        status: (item['status'] as String?)?.trim().toLowerCase() ?? 'present',
        scannedAt: DateTime.parse(item['scanned_at'] as String).toLocal(),
        eventStartTime: event?['start_time'] == null
            ? null
            : DateTime.tryParse(event!['start_time'] as String)?.toLocal(),
        locationName: event?['location_name'] as String?,
        rejectionReason: item['rejection_reason'] as String?,
      );
    }).toList();

    entries.sort((a, b) => b.primaryTimestamp.compareTo(a.primaryTimestamp));
    return entries;
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(_extractError(response));
  }

  String _extractError(http.Response response) {
    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = payload['detail'];
      final error = payload['error'];

      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }

      if (error is String && error.trim().isNotEmpty) {
        return error.trim();
      }
    } catch (_) {
      // ignore parse errors
    }

    return 'Attendance history request failed with status ${response.statusCode}.';
  }
}