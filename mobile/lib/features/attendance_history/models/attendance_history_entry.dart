class AttendanceHistoryEntry {
  const AttendanceHistoryEntry({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.status,
    required this.scannedAt,
    this.eventStartTime,
    this.locationName,
    this.rejectionReason,
  });

  final int id;
  final int eventId;
  final String eventName;
  final String status;
  final DateTime scannedAt;
  final DateTime? eventStartTime;
  final String? locationName;
  final String? rejectionReason;

  bool get isPresent => status.toLowerCase() == 'present';

  bool get isAbsentLike {
    final normalized = status.toLowerCase();
    return normalized == 'absent' || normalized == 'rejected';
  }

  String get normalizedStatusLabel {
    final normalized = status.toLowerCase();

    switch (normalized) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  DateTime get primaryTimestamp => eventStartTime ?? scannedAt;

  String get displayLocation {
    final trimmed = locationName?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'Location not set';
    }
    return trimmed;
  }
}