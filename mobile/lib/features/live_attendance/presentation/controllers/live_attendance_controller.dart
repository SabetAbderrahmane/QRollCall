import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:qrollcall_mobile/features/live_attendance/data/live_attendance_api_service.dart';
import 'package:qrollcall_mobile/features/live_attendance/models/live_attendance_models.dart';

enum LiveAttendanceFilter {
  all,
  present,
  issues,
}

class LiveAttendanceController extends ChangeNotifier {
  LiveAttendanceController({
    required int eventId,
    required LiveAttendanceApiService apiService,
  })  : _eventId = eventId,
        _apiService = apiService;

  final int _eventId;
  final LiveAttendanceApiService _apiService;

  LiveAttendanceSnapshot? snapshot;
  bool isLoading = false;
  bool hasLoadedOnce = false;
  String? errorMessage;

  LiveAttendanceFilter selectedFilter = LiveAttendanceFilter.all;
  String searchQuery = '';

  Timer? _pollingTimer;

  int get eventId => _eventId;

  Future<void> load({bool forceRefresh = false, bool silent = false}) async {
    if (isLoading) return;
    if (hasLoadedOnce && !forceRefresh) return;

    isLoading = !silent;
    errorMessage = null;

    if (!silent) {
      notifyListeners();
    }

    try {
      snapshot = await _apiService.fetchLiveAttendance(eventId: _eventId);
      hasLoadedOnce = true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await load(forceRefresh: true);
  }

  Future<void> refreshSilently() async {
    await load(forceRefresh: true, silent: true);
  }

  void startPolling() {
    _pollingTimer ??= Timer.periodic(
      const Duration(seconds: 10),
      (_) => refreshSilently(),
    );
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void setFilter(LiveAttendanceFilter filter) {
    selectedFilter = filter;
    notifyListeners();
  }

  List<LiveAttendanceStudent> get filteredStudents {
    final data = snapshot;
    if (data == null) return const [];

    Iterable<LiveAttendanceStudent> items = data.students;

    switch (selectedFilter) {
      case LiveAttendanceFilter.all:
        break;
      case LiveAttendanceFilter.present:
        items = items.where((student) => student.isPresent);
        break;
      case LiveAttendanceFilter.issues:
        items = items.where((student) => student.hasIssue);
        break;
    }

    final query = searchQuery.trim().toLowerCase();

    if (query.isNotEmpty) {
      items = items.where((student) {
        return student.fullName.toLowerCase().contains(query) ||
            student.email.toLowerCase().contains(query) ||
            (student.studentId?.toLowerCase().contains(query) ?? false) ||
            student.userId.toString().contains(query);
      });
    }

    return items.toList();
  }

  List<LiveAttendanceStudent> get presentStudents {
    return filteredStudents.where((student) => student.isPresent).toList();
  }

  List<LiveAttendanceStudent> get issueStudents {
    return filteredStudents.where((student) => student.hasIssue).toList();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}