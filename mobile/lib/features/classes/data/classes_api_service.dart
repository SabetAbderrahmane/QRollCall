import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qrollcall_mobile/features/auth/data/firebase_auth_service.dart';
import 'package:qrollcall_mobile/core/config/app_config.dart';

class ClassesApiService {
  ClassesApiService({required this.firebaseAuthService});
  final FirebaseAuthService firebaseAuthService;

  Future<List<dynamic>> fetchJoinedClasses() async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/classes/my'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load joined classes');
  }

  Future<dynamic> fetchClassDetails(int classId) async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/classes/$classId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load class details');
  }

  Future<List<dynamic>> fetchCreatedClasses() async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/classes/created'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load created classes');
  }

  Future<dynamic> createClass(Map<String, dynamic> data) async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/classes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create class');
  }

  Future<List<dynamic>> fetchClassStudents(int classId) async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/classes/$classId/students'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load roster');
  }

  Future<List<dynamic>> fetchClassInvitations(int classId) async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/classes/$classId/invitations'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load invitations');
  }

  Future<dynamic> inviteUser(int classId, Map<String, dynamic> data) async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/classes/$classId/invite'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to invite user');
  }

  Future<List<dynamic>> fetchMyInvitations() async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/classes/me/invitations'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load invitations');
  }

  Future<void> acceptInvitation(int id) async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/classes/invitations/$id/accept'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to accept invitation');
    }
  }

  Future<void> declineInvitation(int id) async {
    final token = await firebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/classes/invitations/$id/decline'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to decline invitation');
    }
  }
}
