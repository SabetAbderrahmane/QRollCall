import 'dart:convert';

class QrScanPayload {
  const QrScanPayload({
    required this.rawValue,
    required this.token,
    this.eventId,
    this.eventName,
    this.startTime,
    this.latitude,
    this.longitude,
    this.geofenceRadiusMeters,
    this.qrValidityMinutes,
  });

  final String rawValue;
  final String token;
  final int? eventId;
  final String? eventName;
  final DateTime? startTime;
  final double? latitude;
  final double? longitude;
  final int? geofenceRadiusMeters;
  final int? qrValidityMinutes;

  String get displayEventName {
    final normalized = eventName?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }

    if (eventId != null) {
      return 'Event #$eventId';
    }

    return 'Attendance Event';
  }

  factory QrScanPayload.fromRaw(String raw) {
    final normalized = raw.trim();

    try {
      final decoded = jsonDecode(normalized);

      if (decoded is Map<String, dynamic> && decoded['token'] is String) {
        return QrScanPayload(
          rawValue: normalized,
          token: (decoded['token'] as String).trim(),
          eventId: decoded['event_id'] as int?,
          eventName: decoded['event_name'] as String?,
          startTime: decoded['start_time'] == null
              ? null
              : DateTime.tryParse(decoded['start_time'] as String)?.toLocal(),
          latitude: (decoded['latitude'] as num?)?.toDouble(),
          longitude: (decoded['longitude'] as num?)?.toDouble(),
          geofenceRadiusMeters: decoded['geofence_radius_meters'] as int?,
          qrValidityMinutes: decoded['qr_validity_minutes'] as int?,
        );
      }
    } catch (_) {
      // Fallback to token-only QR.
    }

    return QrScanPayload(
      rawValue: normalized,
      token: normalized,
    );
  }
}