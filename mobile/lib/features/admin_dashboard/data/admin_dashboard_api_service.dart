import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'package:qrollcall_mobile/core/config/app_config.dart';
import 'package:qrollcall_mobile/features/admin_dashboard/models/admin_dashboard_models.dart';
import 'package:qrollcall_mobile/features/auth/data/firebase_auth_service.dart';

class AdminDashboardApiService {
  AdminDashboardApiService({
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

  Future<AdminDashboardSnapshot> fetchDashboardSnapshot() async {
    final idToken = await _firebaseAuthService.getIdToken(forceRefresh: true);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };

    final eventsResponse = await _client.get(
      _uri('/events', {
        'limit': '20',
        'active_only': 'false',
      }),
      headers: headers,
    );

    final attendanceResponse = await _client.get(
      _uri('/attendance', {
        'limit': '50',
      }),
      headers: headers,
    );

    _ensureSuccess(eventsResponse);
    _ensureSuccess(attendanceResponse);

    final eventsPayload = jsonDecode(eventsResponse.body) as Map<String, dynamic>;
    final attendancePayload =
        jsonDecode(attendanceResponse.body) as Map<String, dynamic>;

    final eventItems = (eventsPayload['items'] as List<dynamic>? ?? const []);
    final attendanceItems =
        (attendancePayload['items'] as List<dynamic>? ?? const []);

    final rawEvents = eventItems
        .map((item) => _RawEvent.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final eventMap = {
      for (final event in rawEvents) event.id: event,
    };

    final now = DateTime.now();

    final liveEvents = rawEvents.where((event) => event.isLiveAt(now)).toList();
    final upcomingEvents = rawEvents
        .where((event) => event.startTime.isAfter(now))
        .toList();

    final selectedEvents = <_RawEvent>[
      ...liveEvents.take(2),
      ...upcomingEvents.take(math.max(0, 4 - liveEvents.take(2).length)),
    ];

    final statsByEventId = <int, _RawAttendanceStats>{};

    if (selectedEvents.isNotEmpty) {
      final statsResponses = await Future.wait(
        selectedEvents.map(
          (event) => _client.get(
            _uri('/attendance/stats/${event.id}'),
            headers: headers,
          ),
        ),
      );

      for (var i = 0; i < statsResponses.length; i++) {
        final response = statsResponses[i];
        _ensureSuccess(response);

        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        statsByEventId[selectedEvents[i].id] =
            _RawAttendanceStats.fromJson(payload);
      }
    }

    final liveAndUpcomingEvents = selectedEvents.map((event) {
      final stats = statsByEventId[event.id];

      return AdminEventSummary(
        id: event.id,
        name: event.name,
        locationName: event.locationName,
        startTime: event.startTime,
        endTime: event.endTime,
        isActive: event.isActive,
        presentCount: stats?.presentCount ?? 0,
        totalRecords: stats?.totalRecords ?? 0,
      );
    }).toList();

    final recentActivity = attendanceItems
        .map((item) => _RawAttendance.fromJson(item as Map<String, dynamic>))
        .map(
          (attendance) => AdminRecentScanActivity(
            id: attendance.id,
            userId: attendance.userId,
            eventName: eventMap[attendance.eventId]?.name ?? 'Event #${attendance.eventId}',
            scannedAt: attendance.scannedAt,
            status: attendance.status,
          ),
        )
        .toList()
      ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));

    final totalEventsToday = rawEvents.where((event) {
      final local = event.startTime;
      return local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
    }).length;

    final studentsPresentNow =
        liveAndUpcomingEvents.where((event) => event.isLiveAt(now)).fold<int>(
      0,
      (sum, event) => sum + event.presentCount,
    );

    final pendingManualChecks = recentActivity
        .where((item) => item.status.toUpperCase() == 'REJECTED')
        .length;

    return AdminDashboardSnapshot(
      totalEventsToday: totalEventsToday,
      studentsPresentNow: studentsPresentNow,
      pendingManualChecks: pendingManualChecks,
      liveAndUpcomingEvents: liveAndUpcomingEvents,
      recentActivity: recentActivity.take(8).toList(),
    );
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(_extractErrorMessage(response));
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = payload['detail'];

      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
    } catch (_) {
      // ignore
    }

    return 'Admin dashboard request failed with status ${response.statusCode}.';
  }
}

class _RawEvent {
  const _RawEvent({
    required this.id,
    required this.name,
    required this.locationName,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  final int id;
  final String name;
  final String locationName;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;

  bool isLiveAt(DateTime now) {
    if (!isActive) return false;
    if (startTime.isAfter(now)) return false;
    if (endTime != null && endTime!.isBefore(now)) return false;
    return true;
  }

  factory _RawEvent.fromJson(Map<String, dynamic> json) {
    return _RawEvent(
      id: json['id'] as int,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : 'Untitled Event',
      locationName: (json['location_name'] as String?)?.trim() ?? '',
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String).toLocal(),
      isActive: json['is_active'] as bool? ?? false,
    );
  }
}

class _RawAttendance {
  const _RawAttendance({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.scannedAt,
    required this.status,
  });

  final int id;
  final int eventId;
  final int userId;
  final DateTime scannedAt;
  final String status;

  factory _RawAttendance.fromJson(Map<String, dynamic> json) {
    return _RawAttendance(
      id: json['id'] as int,
      eventId: json['event_id'] as int,
      userId: json['user_id'] as int,
      scannedAt: DateTime.parse(json['scanned_at'] as String).toLocal(),
      status: (json['status'] as String?)?.trim().toUpperCase() ?? 'PRESENT',
    );
  }
}

class _RawAttendanceStats {
  const _RawAttendanceStats({
    required this.totalRecords,
    required this.presentCount,
  });

  final int totalRecords;
  final int presentCount;

  factory _RawAttendanceStats.fromJson(Map<String, dynamic> json) {
    return _RawAttendanceStats(
      totalRecords: json['total_records'] as int? ?? 0,
      presentCount: json['present_count'] as int? ?? 0,
    );
  }
}