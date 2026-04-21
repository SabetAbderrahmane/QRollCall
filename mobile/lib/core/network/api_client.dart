import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiClient {
  Future<http.Response> get(String path, {Map<String, String>? headers}) {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    return http.get(uri, headers: headers);
  }

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    return http.post(uri, headers: headers, body: body);
  }
}