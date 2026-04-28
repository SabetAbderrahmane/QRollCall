import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:qrollcall_mobile/core/config/app_config.dart';
import 'package:qrollcall_mobile/features/auth/data/firebase_auth_service.dart';
import 'package:qrollcall_mobile/features/create_event/models/create_event_result.dart';

class CreateEventApiService {
  CreateEventApiService({
    required FirebaseAuthService firebaseAuthService,
    http.Client? client,
  })  : _firebaseAuthService = firebaseAuthService,
        _client = client ?? http.Client();

  final FirebaseAuthService _firebaseAuthService;
  final http.Client _client;

  Uri _uri(String path) {
    return Uri.parse('${AppConfig.apiBaseUrl}$path');
  }

  Future<CreateEventResult> createEvent({
    required String name,
    required String? description,
    required DateTime startTimeLocal,
    required String locationName,
    required double latitude,
    required double longitude,
    required int geofenceRadiusMeters,
    required int qrValidityMinutes,
  }) async {
    final idToken = await _firebaseAuthService.getIdToken(forceRefresh: true);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };

    final response = await _client.post(
      _uri('/events'),
      headers: headers,
      body: jsonEncode({
        'name': name.trim(),
        'description': description?.trim().isEmpty == true
            ? null
            : description?.trim(),
        'start_time': startTimeLocal.toUtc().toIso8601String(),
        'end_time': null,
        'location_name': locationName.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'geofence_radius_meters': geofenceRadiusMeters,
        'qr_validity_minutes': qrValidityMinutes,
        'is_active': true,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractError(response));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return CreateEventResult.fromJson(payload);
    
  }

  String _extractError(http.Response response) {
    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = payload['detail'];

      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
    } catch (_) {
      // Ignore parse errors.
    }

    return 'Create event request failed with status ${response.statusCode}.';
  }
}