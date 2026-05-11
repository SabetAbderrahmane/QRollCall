import 'package:flutter/foundation.dart';
import 'package:qrollcall_mobile/features/classes/data/classes_api_service.dart';

class StudentClassesController extends ChangeNotifier {
  StudentClassesController({required this.apiService});

  final ClassesApiService apiService;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<dynamic> _joinedClasses = [];
  List<dynamic> get joinedClasses => _joinedClasses;

  List<dynamic> _invitations = [];
  List<dynamic> get invitations => _invitations;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final futures = await Future.wait([
        apiService.fetchJoinedClasses(),
        apiService.fetchMyInvitations(),
      ]);
      _joinedClasses = futures[0];
      _invitations = futures[1];
    } catch (e) {
      _errorMessage = 'Could not load classes data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptInvitation(int id) async {
    try {
      await apiService.acceptInvitation(id);
      await loadData();
    } catch (e) {
      _errorMessage = 'Failed to accept invitation';
      notifyListeners();
    }
  }

  Future<void> declineInvitation(int id) async {
    try {
      await apiService.declineInvitation(id);
      await loadData();
    } catch (e) {
      _errorMessage = 'Failed to decline invitation';
      notifyListeners();
    }
  }
}
