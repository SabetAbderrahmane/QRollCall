import 'package:flutter/foundation.dart';
import 'package:qrollcall_mobile/features/classes/data/classes_api_service.dart';

class AdminClassDetailsController extends ChangeNotifier {
  AdminClassDetailsController({
    required this.apiService,
    required this.classId,
  });

  final ClassesApiService apiService;
  final int classId;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<dynamic> _students = [];
  List<dynamic> get students => _students;

  List<dynamic> _invitations = [];
  List<dynamic> get invitations => _invitations;

  Future<void> loadDetails() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final futures = await Future.wait([
        apiService.fetchClassStudents(classId),
        apiService.fetchClassInvitations(classId),
      ]);
      _students = futures[0];
      _invitations = futures[1];
    } catch (e) {
      _errorMessage = 'Could not load class details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> inviteUser(String identifier, {bool isUsername = false}) async {
    try {
      final data = <String, dynamic>{};
      if (isUsername) {
        data['username'] = identifier;
      } else {
        data['email'] = identifier;
      }
      
      await apiService.inviteUser(classId, data);
      await loadDetails();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to invite user: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
