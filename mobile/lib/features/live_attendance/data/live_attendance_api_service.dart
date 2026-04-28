import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:qrollcall_mobile/core/config/app_config.dart';
import 'package:qrollcall_mobile/features/auth/data/firebase_auth_service.dart';
import 'package:qrollcall_mobile/features/live_attendance/models/live_attendance_models.dart';

class LiveAttendanceApiService {
  LiveAttendanceApiService({
    required FirebaseAuthService firebaseAuthService,
    http.Client? client,
  })  : _firebaseAuthService = firebaseAuthService,
        _client = client ?? http.Client();

  final FirebaseAuthService _firebaseAuthService;
  final http.Client _client;

  Uri _uri(String path) {
    return Uri.parse('${AppConfig.apiBaseUrl}$path');
  }

  Future<LiveAttendanceSnapshot> fetchLiveAttendance({
    required int eventId,
  }) async {
    final idToken = await _firebaseAuthService.getIdToken(forceRefresh: true);

    final response = await _client.get(
      _uri('/attendance/live/$eventId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractError(response));
    }

    return LiveAttendanceSnapshot.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
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

    return 'Live attendance request failed with status ${response.statusCode}.';
  }
}