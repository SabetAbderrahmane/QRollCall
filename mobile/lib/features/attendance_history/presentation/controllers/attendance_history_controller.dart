import 'package:flutter/foundation.dart';

import 'package:qrollcall_mobile/features/attendance_history/data/attendance_history_api_service.dart';
import 'package:qrollcall_mobile/features/attendance_history/models/attendance_history_entry.dart';

enum AttendanceHistoryFilter {
  all,
  present,
  absent,
}

class AttendanceHistoryController extends ChangeNotifier {
  AttendanceHistoryController({
    required AttendanceHistoryApiService apiService,
  }) : _apiService = apiService;

  final AttendanceHistoryApiService _apiService;

  List<AttendanceHistoryEntry> entries = const [];
  bool isLoading = false;
  bool hasLoadedOnce = false;
  String? errorMessage;
  AttendanceHistoryFilter selectedFilter = AttendanceHistoryFilter.all;

  Future<void> loadHistory({bool forceRefresh = false}) async {
    if (isLoading) return;
    if (hasLoadedOnce && !forceRefresh) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      entries = await _apiService.fetchAttendanceHistory();
      hasLoadedOnce = true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshHistory() async {
    await loadHistory(forceRefresh: true);
  }

  void setFilter(AttendanceHistoryFilter filter) {
    if (selectedFilter == filter) return;
    selectedFilter = filter;
    notifyListeners();
  }

  bool get hasAnyRecords => entries.isNotEmpty;

  int get totalCount => entries.length;

  int get presentCount => entries.where((entry) => entry.isPresent).length;

  int get absentLikeCount => entries.where((entry) => entry.isAbsentLike).length;

  int get attendancePercentage {
    if (totalCount == 0) return 0;
    return ((presentCount / totalCount) * 100).round();
  }

  String get performanceLabel {
    if (totalCount == 0) return 'No Records';
    if (attendancePercentage >= 75) return 'On Track';
    if (attendancePercentage >= 50) return 'Improving';
    return 'Needs Attention';
  }

  List<AttendanceHistoryEntry> get filteredEntries {
    switch (selectedFilter) {
      case AttendanceHistoryFilter.all:
        return entries;
      case AttendanceHistoryFilter.present:
        return entries.where((entry) => entry.isPresent).toList();
      case AttendanceHistoryFilter.absent:
        return entries.where((entry) => entry.isAbsentLike).toList();
    }
  }

  String get emptyStateTitle {
    if (!hasAnyRecords) {
      return 'No records found';
    }

    switch (selectedFilter) {
      case AttendanceHistoryFilter.all:
        return 'No records found';
      case AttendanceHistoryFilter.present:
        return 'No present records';
      case AttendanceHistoryFilter.absent:
        return 'No absent records';
    }
  }

  String get emptyStateSubtitle {
    if (!hasAnyRecords) {
      return 'Your attendance history will appear here once you start scanning codes.';
    }

    switch (selectedFilter) {
      case AttendanceHistoryFilter.all:
        return 'No attendance records are available right now.';
      case AttendanceHistoryFilter.present:
        return 'You do not have any present records in this filter yet.';
      case AttendanceHistoryFilter.absent:
        return 'You do not have any absent or rejected records in this filter.';
    }
  }

  bool get shouldShowPrimaryEmptyAction => !hasAnyRecords;
}