import 'package:flutter/foundation.dart';

import 'package:qrollcall_mobile/features/admin_dashboard/data/admin_dashboard_api_service.dart';
import 'package:qrollcall_mobile/features/admin_dashboard/models/admin_dashboard_models.dart';

class AdminDashboardController extends ChangeNotifier {
  AdminDashboardController({
    required AdminDashboardApiService apiService,
  }) : _apiService = apiService;

  final AdminDashboardApiService _apiService;

  AdminDashboardSnapshot? snapshot;
  bool isLoading = false;
  bool hasLoadedOnce = false;
  String? errorMessage;

  Future<void> loadDashboard({bool forceRefresh = false}) async {
    if (isLoading) return;
    if (hasLoadedOnce && !forceRefresh) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      snapshot = await _apiService.fetchDashboardSnapshot();
      hasLoadedOnce = true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() async {
    await loadDashboard(forceRefresh: true);
  }
}