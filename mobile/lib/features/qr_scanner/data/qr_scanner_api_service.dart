import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:qrollcall_mobile/core/config/app_config.dart';
import 'package:qrollcall_mobile/features/auth/data/firebase_auth_service.dart';
import 'package:qrollcall_mobile/models/attendance_mark_result.dart';

class QrScannerApiException implements Exception {
  const QrScannerApiException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class QrScannerApiService {
  QrScannerApiService({
    required FirebaseAuthService firebaseAuthService,
    http.Client? client,
  })  : _firebaseAuthService = firebaseAuthService,
        _client = client ?? http.Client();

  final FirebaseAuthService _firebaseAuthService;
  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<AttendanceMarkResult> markAttendance({
    required String qrCodeToken,
    required double scanLatitude,
    required double scanLongitude,
    String? deviceId,
  }) async {
    final idToken = await _firebaseAuthService.getIdToken(forceRefresh: true);

    final response = await _client.post(
      _uri('/attendance/mark'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'qr_code_token': qrCodeToken,
        'scan_latitude': scanLatitude,
        'scan_longitude': scanLongitude,
        'device_id': deviceId,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return AttendanceMarkResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw QrScannerApiException(
      statusCode: response.statusCode,
      message: _extractErrorMessage(response),
    );
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = payload['detail'];

      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
    } catch (_) {
      // ignore
    }

    return 'Scanner request failed with status ${response.statusCode}.';
  }
}