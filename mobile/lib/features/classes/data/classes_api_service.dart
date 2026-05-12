import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qrollcall_mobile/features/auth/data/firebase_auth_service.dart';
import 'package:qrollcall_mobile/core/config/app_config.dart';

class ClassesApiService {
  ClassesApiService({required this.firebaseAuthService});
  final FirebaseAuthService firebaseAuthService;

  Uri _uri(String path) {
    final base =
        AppConfig.apiBaseUrl.endsWith('/')
            ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
            : AppConfig.apiBaseUrl;
    final normalizedPath =
        path.startsWith('/api/v1/') ? path.substring('/api/v1'.length) : path;
    final cleanPath =
        normalizedPath.startsWith('/') ? normalizedPath : '/$normalizedPath';

    return Uri.parse('$base$cleanPath');
  }

  Exception _requestFailure(String action, Uri url, http.Response response) {
    return Exception(
      '$action: ${response.statusCode} ${response.body} (url: $url)',
    );
  }

  Future<List<dynamic>> fetchJoinedClasses() async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final url = _uri('/classes/my');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    }
    throw _requestFailure('Failed to load joined classes', url, response);
  }

  Future<dynamic> fetchClassDetails(int classId) async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final url = _uri('/classes/$classId');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw _requestFailure('Failed to load class details', url, response);
  }

  Future<List<dynamic>> fetchCreatedClasses() async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final url = _uri('/classes/created');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    }
    throw _requestFailure('Failed to load created classes', url, response);
  }

  Future<dynamic> createClass(Map<String, dynamic> data) async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final url = _uri('/classes');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw _requestFailure('Failed to create class', url, response);
  }

  Future<List<dynamic>> fetchClassStudents(int classId) async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final url = _uri('/classes/$classId/students');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    }
    throw _requestFailure('Failed to load roster', url, response);
  }

  Future<List<dynamic>> fetchClassInvitations(int classId) async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final url = _uri('/classes/$classId/invitations');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    }
    throw _requestFailure('Failed to load invitations', url, response);
  }

  Future<dynamic> inviteUser(int classId, Map<String, dynamic> data) async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final url = _uri('/classes/$classId/invite');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw _requestFailure('Failed to invite user', url, response);
  }

  Future<List<dynamic>> fetchMyInvitations() async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final url = _uri('/classes/me/invitations');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    }
    throw _requestFailure('Failed to load invitations', url, response);
  }

  Future<void> acceptInvitation(int id) async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final url = _uri('/classes/invitations/$id/accept');
    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw _requestFailure('Failed to accept invitation', url, response);
    }
  }

  Future<void> declineInvitation(int id) async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final url = _uri('/classes/invitations/$id/decline');
    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw _requestFailure('Failed to decline invitation', url, response);
    }
  }
}
