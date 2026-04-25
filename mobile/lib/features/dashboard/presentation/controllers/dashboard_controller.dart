import 'package:flutter/foundation.dart';

import 'package:qrollcall_mobile/features/dashboard/data/dashboard_api_service.dart';
import 'package:qrollcall_mobile/models/attendance_record.dart';
import 'package:qrollcall_mobile/models/event_item.dart';
import 'package:qrollcall_mobile/models/notification_item.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({
    required DashboardApiService dashboardApiService,
  }) : _dashboardApiService = dashboardApiService;

  final DashboardApiService _dashboardApiService;

  List<EventItem> events = const [];
  List<AttendanceRecord> attendanceRecords = const [];
  List<NotificationItem> notifications = const [];

  bool isLoading = false;
  bool hasLoadedOnce = false;
  String? errorMessage;

  Future<void> loadDashboard({bool forceRefresh = false}) async {
    if (isLoading) return;
    if (hasLoadedOnce && !forceRefresh) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final bundle = await _dashboardApiService.fetchDashboardBundle();
      events = bundle.events;
      attendanceRecords = bundle.attendanceRecords;
      notifications = bundle.notifications;
      hasLoadedOnce = true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() async {
    await loadDashboard(forceRefresh: true);
  }

  void clear() {
    events = const [];
    attendanceRecords = const [];
    notifications = const [];
    errorMessage = null;
    hasLoadedOnce = false;
    notifyListeners();
  }

  List<EventItem> get sortedEvents {
    final items = [...events];
    items.sort((a, b) => a.startTime.compareTo(b.startTime));
    return items;
  }

  List<EventItem> get upcomingEvents {
    final now = DateTime.now();
    return sortedEvents
        .where((event) {
          final eventEnd = event.endTime ??
              event.startTime.add(Duration(minutes: event.qrValidityMinutes));
          return eventEnd.isAfter(now);
        })
        .take(3)
        .toList();
  }

  EventItem? get nextEvent {
    if (upcomingEvents.isEmpty) return null;
    return upcomingEvents.first;
  }

  int get unreadNotificationCount =>
      notifications.where((item) => !item.isRead).length;

  int get totalAttendanceCount => attendanceRecords.length;

  int get presentAttendanceCount =>
      attendanceRecords.where((item) => item.isPresent).length;

  int get attendanceRatePercentage {
    if (totalAttendanceCount == 0) return 0;
    return ((presentAttendanceCount / totalAttendanceCount) * 100).round();
  }

  int get monthlyAttendancePresentCount {
    final now = DateTime.now();
    return attendanceRecords.where((item) {
      return item.scannedAt.year == now.year &&
          item.scannedAt.month == now.month &&
          item.isPresent;
    }).length;
  }

  int get monthlyAttendanceTotalCount {
    final now = DateTime.now();
    return attendanceRecords.where((item) {
      return item.scannedAt.year == now.year &&
          item.scannedAt.month == now.month;
    }).length;
  }
}