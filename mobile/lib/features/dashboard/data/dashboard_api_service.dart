import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:qrollcall_mobile/core/config/app_config.dart';
import 'package:qrollcall_mobile/features/auth/data/firebase_auth_service.dart';
import 'package:qrollcall_mobile/models/attendance_record.dart';
import 'package:qrollcall_mobile/models/event_item.dart';
import 'package:qrollcall_mobile/models/notification_item.dart';

class DashboardBundle {
  const DashboardBundle({
    required this.events,
    required this.attendanceRecords,
    required this.notifications,
  });

  final List<EventItem> events;
  final List<AttendanceRecord> attendanceRecords;
  final List<NotificationItem> notifications;
}

class DashboardApiService {
  DashboardApiService({
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

  Future<DashboardBundle> fetchDashboardBundle() async {
    final idToken = await _firebaseAuthService.getIdToken(forceRefresh: true);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };

    final responses = await Future.wait([
      _client.get(
        _uri('/events', {
          'limit': '20',
          'active_only': 'true',
        }),
        headers: headers,
      ),
      _client.get(
        _uri('/attendance', {
          'limit': '100',
        }),
        headers: headers,
      ),
      _client.get(
        _uri('/notifications', {
          'limit': '20',
        }),
        headers: headers,
      ),
    ]);

    final eventsResponse = responses[0];
    final attendanceResponse = responses[1];
    final notificationsResponse = responses[2];

    _ensureSuccess(eventsResponse);
    _ensureSuccess(attendanceResponse);
    _ensureSuccess(notificationsResponse);

    final eventsJson =
        jsonDecode(eventsResponse.body) as Map<String, dynamic>;
    final attendanceJson =
        jsonDecode(attendanceResponse.body) as Map<String, dynamic>;
    final notificationsJson =
        jsonDecode(notificationsResponse.body) as Map<String, dynamic>;

    final events = (eventsJson['items'] as List<dynamic>)
        .map((item) => EventItem.fromJson(item as Map<String, dynamic>))
        .toList();

    final attendanceRecords = (attendanceJson['items'] as List<dynamic>)
        .map((item) => AttendanceRecord.fromJson(item as Map<String, dynamic>))
        .toList();

    final notifications = (notificationsJson['items'] as List<dynamic>)
        .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return DashboardBundle(
      events: events,
      attendanceRecords: attendanceRecords,
      notifications: notifications,
    );
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

      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }
    } catch (_) {
      // ignore parse failures
    }

    return 'Dashboard request failed with status ${response.statusCode}.';
  }
}