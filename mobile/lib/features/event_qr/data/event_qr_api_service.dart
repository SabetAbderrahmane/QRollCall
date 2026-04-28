import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:qrollcall_mobile/core/config/app_config.dart';
import 'package:qrollcall_mobile/features/auth/data/firebase_auth_service.dart';
import 'package:qrollcall_mobile/features/event_qr/models/event_qr_display_data.dart';

class EventQrApiService {
  EventQrApiService({
    required FirebaseAuthService firebaseAuthService,
    http.Client? client,
  })  : _firebaseAuthService = firebaseAuthService,
        _client = client ?? http.Client();

  final FirebaseAuthService _firebaseAuthService;
  final http.Client _client;

  Uri _uri(String path) {
    return Uri.parse('${AppConfig.apiBaseUrl}$path');
  }

  Future<EventQrDisplayData> regenerateQrCode({
    required int eventId,
  }) async {
    final idToken = await _firebaseAuthService.getIdToken(forceRefresh: true);

    final response = await _client.post(
      _uri('/events/$eventId/regenerate-qr'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    _ensureSuccess(response);

    return EventQrDisplayData.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<EventQrDisplayData> endEvent({
    required int eventId,
  }) async {
    final idToken = await _firebaseAuthService.getIdToken(forceRefresh: true);

    final response = await _client.put(
      _uri('/events/$eventId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'is_active': false,
      }),
    );

    _ensureSuccess(response);

    return EventQrDisplayData.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(_extractError(response));
  }

  String _extractError(http.Response response) {
    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = payload['detail'];

      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
    } catch (_) {
      // Ignore JSON parse errors.
    }

    return 'QR action failed with status ${response.statusCode}.';
  }
}