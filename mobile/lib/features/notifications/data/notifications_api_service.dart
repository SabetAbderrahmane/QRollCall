import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:qrollcall_mobile/core/config/app_config.dart';
import 'package:qrollcall_mobile/features/auth/data/firebase_auth_service.dart';
import 'package:qrollcall_mobile/models/notification_item.dart';

class NotificationsApiService {
  NotificationsApiService({
    required FirebaseAuthService firebaseAuthService,
    http.Client? client,
  })  : _firebaseAuthService = firebaseAuthService,
        _client = client ?? http.Client();

  final FirebaseAuthService _firebaseAuthService;
  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse('${AppConfig.apiBaseUrl}$path')
        .replace(queryParameters: queryParameters);
  }

  Future<List<NotificationItem>> fetchNotifications({
    int limit = 50,
    bool? isRead,
  }) async {
    final idToken = await _firebaseAuthService.getIdToken(forceRefresh: true);

    final query = <String, String>{
      'limit': limit.toString(),
    };

    if (isRead != null) {
      query['is_read'] = isRead.toString();
    }

    final response = await _client.get(
      _uri('/notifications', query),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    _ensureSuccess(response);

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final items = payload['items'] as List<dynamic>? ?? const [];

    return items
        .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<NotificationItem> markRead({
    required int notificationId,
    required bool isRead,
  }) async {
    final idToken = await _firebaseAuthService.getIdToken(forceRefresh: true);

    final response = await _client.patch(
      _uri('/notifications/$notificationId/read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'is_read': isRead,
      }),
    );

    _ensureSuccess(response);

    return NotificationItem.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteNotification({
    required int notificationId,
  }) async {
    final idToken = await _firebaseAuthService.getIdToken(forceRefresh: true);

    final response = await _client.delete(
      _uri('/notifications/$notificationId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    _ensureSuccess(response);
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

    return 'Notifications request failed with status ${response.statusCode}.';
  }
}