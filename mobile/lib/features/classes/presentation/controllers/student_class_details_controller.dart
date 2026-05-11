import 'package:flutter/foundation.dart';
import 'package:qrollcall_mobile/features/classes/data/classes_api_service.dart';

class StudentClassDetailsController extends ChangeNotifier {
  StudentClassDetailsController({
    required this.classId,
    required ClassesApiService apiService,
  }) : _apiService = apiService;

  final int classId;
  final ClassesApiService _apiService;

  Map<String, dynamic>? classDetails;
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadDetails() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // In the absence of a specific 'details' endpoint that includes stats,
      // we'll fetch the basic class info and potentially roster if student is allowed.
      // For now, let's just fetch the class object.
      final response = await _apiService.fetchClassDetails(classId);
      classDetails = response as Map<String, dynamic>;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
