import 'package:flutter/foundation.dart';
import 'package:qrollcall_mobile/features/classes/data/classes_api_service.dart';

class AdminClassesController extends ChangeNotifier {
  AdminClassesController({required this.apiService});

  final ClassesApiService apiService;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<dynamic> _createdClasses = [];
  List<dynamic> get createdClasses => _createdClasses;

  Future<void> loadClasses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _createdClasses = await apiService.fetchCreatedClasses();
    } catch (e) {
      _errorMessage = 'Could not load your classes.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createClass(Map<String, dynamic> data) async {
    try {
      await apiService.createClass(data);
      await loadClasses();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create class';
      notifyListeners();
      return false;
    }
  }
}
