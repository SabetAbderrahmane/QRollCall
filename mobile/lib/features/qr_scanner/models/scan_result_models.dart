import 'package:flutter/material.dart';

enum ScanFlowExitAction {
  done,
  retry,
  openHistory,
  home,
}

enum ScanFailureIconKind {
  qrCode,
  time,
  location,
  warning,
  shield,
  lock,
}

class ScanFailureReasonItem {
  const ScanFailureReasonItem({
    required this.iconKind,
    required this.title,
    required this.description,
  });

  final ScanFailureIconKind iconKind;
  final String title;
  final String description;
}

class ScanSuccessViewData {
  const ScanSuccessViewData({
    required this.eventName,
    required this.verifiedAt,
    required this.statusLabel,
    required this.locationLabel,
    required this.eventId,
  });

  final String eventName;
  final DateTime verifiedAt;
  final String statusLabel;
  final String locationLabel;
  final int eventId;
}

class ScanFailureViewData {
  const ScanFailureViewData({
    required this.headline,
    required this.badgeLabel,
    required this.summary,
    required this.reasons,
    this.eventName,
    this.scannedCodePreview,
  });

  final String headline;
  final String badgeLabel;
  final String summary;
  final List<ScanFailureReasonItem> reasons;
  final String? eventName;
  final String? scannedCodePreview;
}

abstract class ScanProcessOutcome {
  const ScanProcessOutcome();
}

class ScanSuccessOutcome extends ScanProcessOutcome {
  const ScanSuccessOutcome(this.data);

  final ScanSuccessViewData data;
}

class ScanFailureOutcome extends ScanProcessOutcome {
  const ScanFailureOutcome(this.data);

  final ScanFailureViewData data;
}

IconData failureIconToMaterial(ScanFailureIconKind kind) {
  switch (kind) {
    case ScanFailureIconKind.qrCode:
      return Icons.qr_code_rounded;
    case ScanFailureIconKind.time:
      return Icons.access_time_rounded;
    case ScanFailureIconKind.location:
      return Icons.location_on_outlined;
    case ScanFailureIconKind.warning:
      return Icons.warning_amber_rounded;
    case ScanFailureIconKind.shield:
      return Icons.shield_outlined;
    case ScanFailureIconKind.lock:
      return Icons.lock_outline_rounded;
  }
}