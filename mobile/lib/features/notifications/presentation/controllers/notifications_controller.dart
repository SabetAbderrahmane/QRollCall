import 'package:flutter/foundation.dart';

import 'package:qrollcall_mobile/features/notifications/data/notifications_api_service.dart';
import 'package:qrollcall_mobile/models/notification_item.dart';

enum NotificationsFilter {
  all,
  unread,
  read,
}

class NotificationsController extends ChangeNotifier {
  NotificationsController({
    required NotificationsApiService apiService,
  }) : _apiService = apiService;

  final NotificationsApiService _apiService;

  List<NotificationItem> notifications = const [];

  bool isLoading = false;
  bool hasLoadedOnce = false;
  bool isMutating = false;
  String? errorMessage;

  NotificationsFilter selectedFilter = NotificationsFilter.all;

  int get unreadCount {
    return notifications.where((item) => !item.isRead).length;
  }

  List<NotificationItem> get filteredNotifications {
    switch (selectedFilter) {
      case NotificationsFilter.all:
        return notifications;
      case NotificationsFilter.unread:
        return notifications.where((item) => !item.isRead).toList();
      case NotificationsFilter.read:
        return notifications.where((item) => item.isRead).toList();
    }
  }

  Future<void> load({bool forceRefresh = false}) async {
    if (isLoading) return;
    if (hasLoadedOnce && !forceRefresh) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      notifications = await _apiService.fetchNotifications(limit: 50);
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

  void setFilter(NotificationsFilter filter) {
    selectedFilter = filter;
    notifyListeners();
  }

  Future<void> markNotificationRead(
    NotificationItem item, {
    required bool isRead,
  }) async {
    if (isMutating) return;

    isMutating = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _apiService.markRead(
        notificationId: item.id,
        isRead: isRead,
      );
      await refresh();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    if (isMutating) return;

    final unreadItems = notifications.where((item) => !item.isRead).toList();

    if (unreadItems.isEmpty) {
      return;
    }

    isMutating = true;
    errorMessage = null;
    notifyListeners();

    try {
      for (final item in unreadItems) {
        await _apiService.markRead(
          notificationId: item.id,
          isRead: true,
        );
      }

      await refresh();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  Future<void> deleteNotification(NotificationItem item) async {
    if (isMutating) return;

    isMutating = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteNotification(notificationId: item.id);
      await refresh();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }
}