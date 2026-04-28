import 'dart:convert';

class EventQrDisplayData {
  const EventQrDisplayData({
    required this.id,
    required this.name,
    required this.qrCodeToken,
    required this.startTime,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadiusMeters,
    required this.qrValidityMinutes,
    required this.isActive,
    this.endTime,
    this.locationName,
    this.qrCodeImagePath,
  });

  final int id;
  final String name;
  final String qrCodeToken;
  final DateTime startTime;
  final DateTime? endTime;
  final String? locationName;
  final double latitude;
  final double longitude;
  final int geofenceRadiusMeters;
  final int qrValidityMinutes;
  final bool isActive;
  final String? qrCodeImagePath;

  factory EventQrDisplayData.fromJson(Map<String, dynamic> json) {
    return EventQrDisplayData(
      id: json['id'] as int,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : 'Untitled Event',
      qrCodeToken: json['qr_code_token'] as String,
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String).toLocal(),
      locationName: json['location_name'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      geofenceRadiusMeters: json['geofence_radius_meters'] as int? ?? 100,
      qrValidityMinutes: json['qr_validity_minutes'] as int? ?? 15,
      isActive: json['is_active'] as bool? ?? true,
      qrCodeImagePath: json['qr_code_image_path'] as String?,
    );
  }

  EventQrDisplayData copyWith({
    String? qrCodeToken,
    bool? isActive,
    String? qrCodeImagePath,
  }) {
    return EventQrDisplayData(
      id: id,
      name: name,
      qrCodeToken: qrCodeToken ?? this.qrCodeToken,
      startTime: startTime,
      endTime: endTime,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      geofenceRadiusMeters: geofenceRadiusMeters,
      qrValidityMinutes: qrValidityMinutes,
      isActive: isActive ?? this.isActive,
      qrCodeImagePath: qrCodeImagePath ?? this.qrCodeImagePath,
    );
  }

  String get locationLabel {
    final trimmed = locationName?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'Location not set';
    }
    return trimmed;
  }

  DateTime get validFrom {
    return startTime.subtract(Duration(minutes: qrValidityMinutes));
  }

  DateTime get validUntil {
    return startTime.add(Duration(minutes: qrValidityMinutes));
  }

  String get qrPayloadJson {
    return jsonEncode({
      'event_id': id,
      'event_name': name,
      'start_time': startTime.toUtc().toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'geofence_radius_meters': geofenceRadiusMeters,
      'qr_validity_minutes': qrValidityMinutes,
      'token': qrCodeToken,
    });
  }
}