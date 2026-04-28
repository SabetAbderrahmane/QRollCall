import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:qrollcall_mobile/features/event_qr/data/event_qr_api_service.dart';
import 'package:qrollcall_mobile/features/event_qr/models/event_qr_display_data.dart';

enum EventQrWindowState {
  notOpenYet,
  active,
  expired,
  ended,
}

class EventQrController extends ChangeNotifier {
  EventQrController({
    required EventQrDisplayData initialData,
    required EventQrApiService apiService,
  })  : event = initialData,
        _apiService = apiService {
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );
  }

  final EventQrApiService _apiService;

  EventQrDisplayData event;
  Timer? _ticker;

  bool isRegenerating = false;
  bool isEnding = false;
  String? errorMessage;

  EventQrWindowState get windowState {
    if (!event.isActive) {
      return EventQrWindowState.ended;
    }

    final now = DateTime.now();

    if (now.isBefore(event.validFrom)) {
      return EventQrWindowState.notOpenYet;
    }

    if (now.isAfter(event.validUntil)) {
      return EventQrWindowState.expired;
    }

    return EventQrWindowState.active;
  }

  bool get canRegenerate {
    return event.isActive && !isRegenerating && !isEnding;
  }

  bool get canEnd {
    return event.isActive && !isEnding;
  }

  String get qrPayloadJson => event.qrPayloadJson;

  String get validityLabel {
    switch (windowState) {
      case EventQrWindowState.notOpenYet:
        return 'Opens in';
      case EventQrWindowState.active:
        return 'Expires in';
      case EventQrWindowState.expired:
        return 'Expired';
      case EventQrWindowState.ended:
        return 'Ended';
    }
  }

  String get countdownText {
    final now = DateTime.now();

    switch (windowState) {
      case EventQrWindowState.notOpenYet:
        return _formatDuration(event.validFrom.difference(now));
      case EventQrWindowState.active:
        return _formatDuration(event.validUntil.difference(now));
      case EventQrWindowState.expired:
      case EventQrWindowState.ended:
        return '00:00';
    }
  }

  String get timeRangeLabel {
    final start = _formatTime(event.startTime);
    final end = event.endTime == null ? null : _formatTime(event.endTime!);

    if (end == null) {
      return 'Today, $start';
    }

    return 'Today, $start - $end';
  }

  Future<bool> regenerateCode() async {
    if (!canRegenerate) return false;

    isRegenerating = true;
    errorMessage = null;
    notifyListeners();

    try {
      event = await _apiService.regenerateQrCode(eventId: event.id);
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isRegenerating = false;
      notifyListeners();
    }
  }

  Future<bool> endEvent() async {
    if (!canEnd) return false;

    isEnding = true;
    errorMessage = null;
    notifyListeners();

    try {
      event = await _apiService.endEvent(eventId: event.id);
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isEnding = false;
      notifyListeners();
    }
  }

  static String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds <= 0 ? 0 : duration.inSeconds;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;

      return '$hours:${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }

    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
            ? value.hour - 12
            : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $suffix';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}