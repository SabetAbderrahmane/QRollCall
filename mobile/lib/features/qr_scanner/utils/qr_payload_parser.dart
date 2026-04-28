import 'dart:convert';

String extractQrToken(String rawValue) {
  final trimmed = rawValue.trim();

  if (trimmed.isEmpty) {
    return trimmed;
  }

  try {
    final decoded = jsonDecode(trimmed);

    if (decoded is Map<String, dynamic>) {
      final token = decoded['token'] ?? decoded['qr_code_token'];

      if (token is String && token.trim().isNotEmpty) {
        return token.trim();
      }
    }
  } catch (_) {
    // Not JSON. Treat as raw token.
  }

  return trimmed;
}