class EventItem {
  const EventItem({
    required this.id,
    required this.name,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadiusMeters,
    required this.qrValidityMinutes,
    required this.isActive,
    required this.qrCodeToken,
    required this.qrCodeImagePath,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final String? locationName;
  final double latitude;
  final double longitude;
  final int geofenceRadiusMeters;
  final int qrValidityMinutes;
  final bool isActive;
  final String qrCodeToken;
  final String? qrCodeImagePath;
  final int createdByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String).toLocal(),
      locationName: json['location_name'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      geofenceRadiusMeters: json['geofence_radius_meters'] as int,
      qrValidityMinutes: json['qr_validity_minutes'] as int,
      isActive: json['is_active'] as bool,
      qrCodeToken: json['qr_code_token'] as String,
      qrCodeImagePath: json['qr_code_image_path'] as String?,
      createdByUserId: json['created_by_user_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }
}