import 'package:flutter/material.dart';

import 'package:qrollcall_mobile/features/create_event/data/create_event_api_service.dart';
import 'package:qrollcall_mobile/features/create_event/models/create_event_result.dart';

class CreateEventController extends ChangeNotifier {
  CreateEventController({
    required CreateEventApiService apiService,
  }) : _apiService = apiService;

  final CreateEventApiService _apiService;

  final eventNameController = TextEditingController();
  final locationController = TextEditingController();
  final latitudeController = TextEditingController(text: '36.752887');
  final longitudeController = TextEditingController(text: '3.042048');
  final notesController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  int qrValidityMinutes = 15;
  int geofenceRadiusMeters = 100;

  bool isSubmitting = false;
  String? errorMessage;
  CreateEventResult? createdEvent;

  void setSelectedDate(DateTime value) {
    selectedDate = DateTime(
      value.year,
      value.month,
      value.day,
      selectedDate.hour,
      selectedDate.minute,
    );
    notifyListeners();
  }

  void setSelectedTime(TimeOfDay value) {
    selectedTime = value;
    notifyListeners();
  }

  void setQrValidityMinutes(int value) {
    qrValidityMinutes = value.clamp(5, 60);
    notifyListeners();
  }

  void setGeofenceRadiusMeters(double value) {
    geofenceRadiusMeters = value.round().clamp(25, 500);
    notifyListeners();
  }

  Future<bool> submit() async {
    errorMessage = null;
    createdEvent = null;

    final eventName = eventNameController.text.trim();
    final locationName = locationController.text.trim();
    final latitude = double.tryParse(latitudeController.text.trim());
    final longitude = double.tryParse(longitudeController.text.trim());

    if (eventName.isEmpty) {
      errorMessage = 'Event name is required.';
      notifyListeners();
      return false;
    }

    if (locationName.isEmpty) {
      errorMessage = 'Event location is required.';
      notifyListeners();
      return false;
    }

    if (latitude == null || latitude < -90 || latitude > 90) {
      errorMessage = 'Enter a valid latitude between -90 and 90.';
      notifyListeners();
      return false;
    }

    if (longitude == null || longitude < -180 || longitude > 180) {
      errorMessage = 'Enter a valid longitude between -180 and 180.';
      notifyListeners();
      return false;
    }

    isSubmitting = true;
    notifyListeners();

    try {
      final localStartTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      createdEvent = await _apiService.createEvent(
        name: eventName,
        description: notesController.text,
        startTimeLocal: localStartTime,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        geofenceRadiusMeters: geofenceRadiusMeters,
        qrValidityMinutes: qrValidityMinutes,
      );

      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  String get formattedDate {
    const monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${monthNames[selectedDate.month - 1]} ${selectedDate.day}, ${selectedDate.year}';
  }

  String get formattedTime {
    final hour = selectedTime.hour == 0
        ? 12
        : selectedTime.hour > 12
            ? selectedTime.hour - 12
            : selectedTime.hour;
    final minute = selectedTime.minute.toString().padLeft(2, '0');
    final suffix = selectedTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  @override
  void dispose() {
    eventNameController.dispose();
    locationController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    notesController.dispose();
    super.dispose();
  }
}