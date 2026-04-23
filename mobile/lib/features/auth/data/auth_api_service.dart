import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../models/app_user.dart';

class AuthApiService {
  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Map<String, String> _headers(String idToken) {
    return <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };
  }

  Future<void> syncUser(String idToken) async {
    final response = await _client.post(
      _uri('/auth/sync-user'),
      headers: _headers(idToken),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractError(response));
    }
  }

  Future<AppUser> getCurrentUser(String idToken) async {
    final response = await _client.get(
      _uri('/auth/me'),
      headers: _headers(idToken),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractError(response));
    }

    return AppUser.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  String _extractError(http.Response response) {
    try {
      final Map<String, dynamic> payload =
          jsonDecode(response.body) as Map<String, dynamic>;

      final detail = payload['detail'];
      final error = payload['error'];

      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }

      if (error is String && error.trim().isNotEmpty) {
        return error;
      }
    } catch (_) {
      // fall through
    }

    return 'Request failed with status ${response.statusCode}.';
  }
}