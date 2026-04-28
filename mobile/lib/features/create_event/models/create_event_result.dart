import 'package:qrollcall_mobile/features/event_qr/models/event_qr_display_data.dart';

class CreateEventResult {
  const CreateEventResult({
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

  factory CreateEventResult.fromJson(Map<String, dynamic> json) {
    return CreateEventResult(
      id: json['id'] as int,
      name: json['name'] as String,
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

  EventQrDisplayData toEventQrDisplayData() {
    return EventQrDisplayData(
      id: id,
      name: name,
      qrCodeToken: qrCodeToken,
      startTime: startTime,
      endTime: endTime,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      geofenceRadiusMeters: geofenceRadiusMeters,
      qrValidityMinutes: qrValidityMinutes,
      isActive: isActive,
      qrCodeImagePath: qrCodeImagePath,
    );
  }
}