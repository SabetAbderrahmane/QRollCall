import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'package:qrollcall_mobile/features/qr_scanner/data/qr_scanner_api_service.dart';
import 'package:qrollcall_mobile/features/qr_scanner/models/scan_result_models.dart';

import 'package:qrollcall_mobile/models/qr_scan_payload.dart';

class QrScannerController extends ChangeNotifier {
  QrScannerController({
    required QrScannerApiService qrScannerApiService,
  }) : _qrScannerApiService = qrScannerApiService;

  final QrScannerApiService _qrScannerApiService;

  bool isProcessing = false;
  String? inlineErrorMessage;

  void reset() {
    isProcessing = false;
    inlineErrorMessage = null;
    notifyListeners();
  }

  Future<ScanProcessOutcome> processDetectedValue(String rawValue) async {
    isProcessing = true;
    inlineErrorMessage = null;
    notifyListeners();

    try {
      final payload = QrScanPayload.fromRaw(rawValue);

      if (payload.token.trim().isEmpty) {
        return ScanFailureOutcome(
          _buildGenericFailure(
            headline: 'Unreadable QR Code',
            badge: 'Scanner Error',
            summary: 'The scanned code does not contain a usable attendance token.',
            reasons: const [
              ScanFailureReasonItem(
                iconKind: ScanFailureIconKind.qrCode,
                title: 'Invalid scan payload',
                description:
                    'Ask the organizer to regenerate the event QR code and try scanning again.',
              ),
            ],
          ),
        );
      }

      final position = await _resolvePosition();

      final markResult = await _qrScannerApiService.markAttendance(
        qrCodeToken: payload.token,
        scanLatitude: position.latitude,
        scanLongitude: position.longitude,
        deviceId: _buildDeviceId(),
      );

      if (markResult.isPresent) {
        return ScanSuccessOutcome(
          ScanSuccessViewData(
            eventName: payload.displayEventName,
            verifiedAt: markResult.scannedAt,
            statusLabel: 'Verified Present',
            locationLabel: payload.geofenceRadiusMeters != null
                ? 'Location verified inside ${payload.geofenceRadiusMeters}m geofence'
                : 'Location verified for this attendance session',
            eventId: markResult.eventId,
          ),
        );
      }

      return ScanFailureOutcome(
        _buildFailureFromReason(
          reason: markResult.rejectionReason ?? 'Attendance was rejected.',
          payload: payload,
        ),
      );
    } on QrScannerApiException catch (error) {
      return ScanFailureOutcome(
        _buildFailureFromApiException(error),
      );
    } on LocationServiceDisabledException {
      return ScanFailureOutcome(
        _buildGenericFailure(
          headline: 'Location Services Off',
          badge: 'Location Required',
          summary: 'Location services must be enabled before attendance can be recorded.',
          reasons: const [
            ScanFailureReasonItem(
              iconKind: ScanFailureIconKind.location,
              title: 'Enable device location',
              description:
                  'Turn on GPS/location services, then try scanning the event QR code again.',
            ),
          ],
        ),
      );
    } on LocationPermissionDeniedException {
      return ScanFailureOutcome(
        _buildGenericFailure(
          headline: 'Location Permission Needed',
          badge: 'Permission Required',
          summary: 'QRollCall needs location access to verify the event geofence.',
          reasons: const [
            ScanFailureReasonItem(
              iconKind: ScanFailureIconKind.lock,
              title: 'Permission denied',
              description:
                  'Grant location permission to the app and retry the scan.',
            ),
          ],
        ),
      );
    } catch (error) {
      return ScanFailureOutcome(
        _buildGenericFailure(
          headline: 'Scan Failed',
          badge: 'Unexpected Error',
          summary: 'An unexpected issue occurred while processing your attendance.',
          reasons: [
            ScanFailureReasonItem(
              iconKind: ScanFailureIconKind.warning,
              title: 'Technical error',
              description: error.toString().replaceFirst('Exception: ', ''),
            ),
          ],
        ),
      );
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  Future<Position> _resolvePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedException();
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  String _buildDeviceId() {
    return 'flutter-${defaultTargetPlatform.name}';
  }

  ScanFailureViewData _buildFailureFromApiException(
    QrScannerApiException exception,
  ) {
    final reason = exception.message.toLowerCase();

    if (exception.statusCode == 409 || reason.contains('already marked')) {
      return _buildGenericFailure(
        headline: 'Attendance Already Marked',
        badge: 'Duplicate Scan',
        summary: 'This account has already been recorded for the scanned event.',
        reasons: const [
          ScanFailureReasonItem(
            iconKind: ScanFailureIconKind.shield,
            title: 'Duplicate attendance blocked',
            description:
                'QRollCall prevents multiple present records for the same user and event.',
          ),
        ],
      );
    }

    if (exception.statusCode == 404 || reason.contains('invalid qr')) {
      return _buildGenericFailure(
        headline: 'Invalid QR Code',
        badge: 'Verification Error',
        summary: 'The scanned code is not recognized by the current event registry.',
        reasons: const [
          ScanFailureReasonItem(
            iconKind: ScanFailureIconKind.qrCode,
            title: 'Token not recognized',
            description:
                'The event QR code may be expired, corrupted, or generated for a different session.',
          ),
        ],
      );
    }

    if (exception.statusCode == 401) {
      return _buildGenericFailure(
        headline: 'Session Expired',
        badge: 'Authentication Required',
        summary: 'Your sign-in session is no longer valid for attendance marking.',
        reasons: const [
          ScanFailureReasonItem(
            iconKind: ScanFailureIconKind.lock,
            title: 'Sign in again',
            description:
                'Return to the dashboard, log in again, and retry the scan.',
          ),
        ],
      );
    }

    return _buildGenericFailure(
      headline: 'Scan Failed',
      badge: 'Server Error',
      summary: exception.message,
      reasons: [
        ScanFailureReasonItem(
          iconKind: ScanFailureIconKind.warning,
          title: 'Request failed',
          description: exception.message,
        ),
      ],
    );
  }

  ScanFailureViewData _buildFailureFromReason({
    required String reason,
    required QrScanPayload payload,
  }) {
    final normalized = reason.toLowerCase();

    if (normalized.contains('time window')) {
      return _buildGenericFailure(
        headline: 'Outside Time Window',
        badge: 'Verification Error',
        summary:
            '${payload.displayEventName} can only be scanned inside its allowed attendance window.',
        eventName: payload.displayEventName,
        reasons: const [
          ScanFailureReasonItem(
            iconKind: ScanFailureIconKind.time,
            title: 'Attendance window closed',
            description:
                'The QR code was scanned too early or too late for this session.',
          ),
        ],
      );
    }

    if (normalized.contains('geofence') || normalized.contains('location')) {
      final radiusText = payload.geofenceRadiusMeters != null
          ? 'Move inside the designated ${payload.geofenceRadiusMeters}m event zone and try again.'
          : 'Move inside the designated event zone and try again.';

      return _buildGenericFailure(
        headline: 'Wrong Location',
        badge: 'Location Required',
        summary:
            'Your device location is outside the allowed geofence for ${payload.displayEventName}.',
        eventName: payload.displayEventName,
        reasons: [
          ScanFailureReasonItem(
            iconKind: ScanFailureIconKind.location,
            title: 'Outside event geofence',
            description: radiusText,
          ),
        ],
      );
    }

    if (normalized.contains('already marked')) {
      return _buildGenericFailure(
        headline: 'Attendance Already Marked',
        badge: 'Duplicate Scan',
        summary: 'A previous attendance record already exists for this event.',
        eventName: payload.displayEventName,
        reasons: const [
          ScanFailureReasonItem(
            iconKind: ScanFailureIconKind.shield,
            title: 'Duplicate attendance blocked',
            description:
                'QRollCall prevents multiple check-ins for the same user and event.',
          ),
        ],
      );
    }

    return _buildGenericFailure(
      headline: 'Scan Failed',
      badge: 'Verification Error',
      summary: reason,
      eventName: payload.displayEventName,
      reasons: [
        ScanFailureReasonItem(
          iconKind: ScanFailureIconKind.warning,
          title: 'Attendance rejected',
          description: reason,
        ),
      ],
    );
  }

  ScanFailureViewData _buildGenericFailure({
    required String headline,
    required String badge,
    required String summary,
    required List<ScanFailureReasonItem> reasons,
    String? eventName,
  }) {
    return ScanFailureViewData(
      headline: headline,
      badgeLabel: badge,
      summary: summary,
      reasons: reasons,
      eventName: eventName,
    );
  }
}

class LocationServiceDisabledException implements Exception {}

class LocationPermissionDeniedException implements Exception {}