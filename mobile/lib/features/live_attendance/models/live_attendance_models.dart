class LiveAttendanceSnapshot {
  const LiveAttendanceSnapshot({
    required this.eventId,
    required this.eventName,
    required this.startTime,
    required this.isActive,
    required this.totalRecords,
    required this.presentCount,
    required this.absentCount,
    required this.rejectedCount,
    required this.students,
    this.locationName,
    this.endTime,
  });

  final int eventId;
  final String eventName;
  final String? locationName;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;

  final int totalRecords;
  final int presentCount;
  final int absentCount;
  final int rejectedCount;

  final List<LiveAttendanceStudent> students;

  factory LiveAttendanceSnapshot.fromJson(Map<String, dynamic> json) {
    final rawStudents = json['students'] as List<dynamic>? ?? const [];

    return LiveAttendanceSnapshot(
      eventId: json['event_id'] as int,
      eventName: (json['event_name'] as String?)?.trim().isNotEmpty == true
          ? (json['event_name'] as String).trim()
          : 'Untitled Event',
      locationName: json['location_name'] as String?,
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String).toLocal(),
      isActive: json['is_active'] as bool? ?? false,
      totalRecords: json['total_records'] as int? ?? 0,
      presentCount: json['present_count'] as int? ?? 0,
      absentCount: json['absent_count'] as int? ?? 0,
      rejectedCount: json['rejected_count'] as int? ?? 0,
      students: rawStudents
          .map((item) => LiveAttendanceStudent.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  int get issueCount => absentCount + rejectedCount;

  int get attendanceRate {
    if (totalRecords <= 0) return 0;
    return ((presentCount / totalRecords) * 100).round();
  }

  String get locationLabel {
    final trimmed = locationName?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'Location not set';
    }
    return trimmed;
  }

  String get timeLabel {
    final start = _formatTime(startTime);
    if (endTime == null) return start;
    return '$start - ${_formatTime(endTime!)}';
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
            ? value.hour - 12
            : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $suffix';
  }
}

class LiveAttendanceStudent {
  const LiveAttendanceStudent({
    required this.attendanceId,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.status,
    required this.scannedAt,
    required this.entryMethod,
    this.studentId,
    this.profileImageUrl,
    this.deviceId,
    this.rejectionReason,
  });

  final int attendanceId;
  final int userId;
  final String fullName;
  final String email;
  final String? studentId;
  final String? profileImageUrl;

  final String status;
  final DateTime scannedAt;
  final String entryMethod;
  final String? deviceId;
  final String? rejectionReason;

  factory LiveAttendanceStudent.fromJson(Map<String, dynamic> json) {
    return LiveAttendanceStudent(
      attendanceId: json['attendance_id'] as int,
      userId: json['user_id'] as int,
      fullName: (json['full_name'] as String?)?.trim().isNotEmpty == true
          ? (json['full_name'] as String).trim()
          : (json['email'] as String? ?? 'Student #${json['user_id']}'),
      email: json['email'] as String? ?? '',
      studentId: json['student_id'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      status: (json['status'] as String?)?.trim().toLowerCase() ?? 'present',
      scannedAt: DateTime.parse(json['scanned_at'] as String).toLocal(),
      entryMethod: json['entry_method'] as String? ?? 'In-app QR',
      deviceId: json['device_id'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

  bool get isPresent => status.toLowerCase() == 'present';

  bool get hasIssue => !isPresent;

  String get statusLabel {
    final normalized = status.toLowerCase();

    if (normalized == 'present') return 'Verified';
    if (normalized == 'rejected') return 'Rejected';
    if (normalized == 'absent') return 'Absent';

    return status;
  }

  String get scannedTimeLabel {
    final hour = scannedAt.hour == 0
        ? 12
        : scannedAt.hour > 12
            ? scannedAt.hour - 12
            : scannedAt.hour;
    final minute = scannedAt.minute.toString().padLeft(2, '0');
    final suffix = scannedAt.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $suffix';
  }

  String get subtitle {
    if (hasIssue && rejectionReason != null && rejectionReason!.trim().isNotEmpty) {
      return rejectionReason!;
    }

    return '$scannedTimeLabel • $entryMethod';
  }

  String get avatarLabel {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}