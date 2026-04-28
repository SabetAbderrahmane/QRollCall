import 'dart:math' as math;

enum AdminEventKind { live, upcoming }

class AdminEventSummary {
  const AdminEventSummary({
    required this.id,
    required this.name,
    required this.locationName,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.presentCount,
    required this.totalRecords,
  });

  final int id;
  final String name;
  final String locationName;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;
  final int presentCount;
  final int totalRecords;

  bool isLiveAt(DateTime now) {
    if (!isActive) return false;
    if (startTime.isAfter(now)) return false;
    if (endTime != null && endTime!.isBefore(now)) return false;
    return true;
  }

  AdminEventKind kindAt(DateTime now) {
    return isLiveAt(now) ? AdminEventKind.live : AdminEventKind.upcoming;
  }

  double get attendanceProgress {
    if (totalRecords <= 0) return 0;
    return (presentCount / totalRecords).clamp(0, 1);
  }

  String subtitle(DateTime now) {
    final location = locationName.trim().isEmpty ? 'Location not set' : locationName;

    if (isLiveAt(now)) {
      final timeText = endTime == null ? 'Live now' : 'Session ends ${formatTime(endTime!)}';
      return '$location • $timeText';
    }

    return '$location • Starts at ${formatTime(startTime)}';
  }

  String badgeLabel(DateTime now) {
    if (isLiveAt(now)) return 'LIVE';
    return 'UPCOMING: ${formatTime(startTime)}';
  }

  static String formatTime(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
            ? value.hour - 12
            : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${minute} $suffix';
  }

  List<String> previewAudienceChips() {
    final count = math.max(totalRecords, presentCount);

    if (count <= 0) {
      return const ['--'];
    }
    if (count == 1) {
      return const ['+1'];
    }
    if (count == 2) {
      return const ['+2'];
    }
    return ['+${count.clamp(3, 99)}'];
  }
}

class AdminRecentScanActivity {
  const AdminRecentScanActivity({
    required this.id,
    required this.userId,
    required this.eventName,
    required this.scannedAt,
    required this.status,
  });

  final int id;
  final int userId;
  final String eventName;
  final DateTime scannedAt;
  final String status;

  bool get isVerified => status.toUpperCase() == 'PRESENT';

  String get statusLabel {
    if (status.toUpperCase() == 'PRESENT') return 'Verified';
    if (status.toUpperCase() == 'REJECTED') return 'Rejected';
    if (status.toUpperCase() == 'ABSENT') return 'Absent';
    return status;
  }

  String get userLabel => 'Student #$userId';

  String relativeTime(DateTime now) {
    final difference = now.difference(scannedAt);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} mins ago';
    if (difference.inHours < 24) return '${difference.inHours} hrs ago';
    return '${difference.inDays} days ago';
  }
}

class AdminDashboardSnapshot {
  const AdminDashboardSnapshot({
    required this.totalEventsToday,
    required this.studentsPresentNow,
    required this.pendingManualChecks,
    required this.liveAndUpcomingEvents,
    required this.recentActivity,
  });

  final int totalEventsToday;
  final int studentsPresentNow;
  final int pendingManualChecks;
  final List<AdminEventSummary> liveAndUpcomingEvents;
  final List<AdminRecentScanActivity> recentActivity;
}