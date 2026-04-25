class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.scannedAt,
    required this.status,
    required this.scanLatitude,
    required this.scanLongitude,
    required this.deviceId,
    required this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int eventId;
  final int userId;
  final DateTime scannedAt;
  final String status;
  final double? scanLatitude;
  final double? scanLongitude;
  final String? deviceId;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPresent => status.toLowerCase() == 'present';

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as int,
      eventId: json['event_id'] as int,
      userId: json['user_id'] as int,
      scannedAt: DateTime.parse(json['scanned_at'] as String).toLocal(),
      status: json['status'] as String,
      scanLatitude: (json['scan_latitude'] as num?)?.toDouble(),
      scanLongitude: (json['scan_longitude'] as num?)?.toDouble(),
      deviceId: json['device_id'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }
}