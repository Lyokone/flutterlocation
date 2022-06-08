import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:location_platform_interface/messages.pigeon.dart';

export 'package:location_platform_interface/messages.pigeon.dart'
    show LocationData, LocationAccuracy, LocationSettings, PermissionStatus;

LocationPlatform get _platform => LocationPlatform.instance;

/// Returns the current location.
Future<LocationData> getLocation() async {
  final location = await _platform.getLocation();
  if (location == null) throw Exception('Unable to get location');
  return location;
}

/// Listen to the current location.
Stream<LocationData> get onLocationChanged {
  return _platform.onLocationChanged
      .where((event) => event != null)
      .cast<LocationData>();
}

/// Listen to the current location.
Future<void> setLocationSettings({
  bool askForPermission = true,
  String rationaleMessageForPermissionRequest =
      'The app needs to access your location',
  String rationaleMessageForGPSRequest =
      'The app needs to access your location',
  bool useGooglePlayServices = true,
  bool askForGooglePlayServices = false,
  bool askForGPS = true,
  bool fallbackToGPS = true,
  bool ignoreLastKnownPosition = false,
  double? expirationDuration,
  double? expirationTime,
  double fastestInterval = 500,
  double interval = 1000,
  double? maxWaitTime,
  int? numUpdates,
  LocationAccuracy accuracy = LocationAccuracy.high,
  double smallestDisplacement = 0,
  bool waitForAccurateLocation = true,
}) async {
  final response = await _platform.setLocationSettings(
    LocationSettings(
      askForPermission: askForPermission,
      rationaleMessageForPermissionRequest:
          rationaleMessageForPermissionRequest,
      rationaleMessageForGPSRequest: rationaleMessageForGPSRequest,
      useGooglePlayServices: useGooglePlayServices,
      askForGooglePlayServices: askForGooglePlayServices,
      askForGPS: askForGPS,
      fallbackToGPS: fallbackToGPS,
      ignoreLastKnownPosition: ignoreLastKnownPosition,
      expirationDuration: expirationDuration,
      expirationTime: expirationTime,
      fastestInterval: fastestInterval,
      interval: interval,
      maxWaitTime: maxWaitTime,
      numUpdates: numUpdates,
      accuracy: accuracy,
      smallestDisplacement: smallestDisplacement,
      waitForAccurateLocation: waitForAccurateLocation,
    ),
  );
  if (response != true) throw Exception('Unable to set new location settings');
}

/// Get permission status.
Future<PermissionStatus> getPermissionStatus() async {
  final response = await _platform.getPermissionStatus();
  if (response == null) {
    throw Exception('Error while getting permission status');
  }
  return response;
}

/// Get permission status.
Future<PermissionStatus> requestPermission() async {
  final response = await _platform.requestPermission();
  if (response == null) {
    throw Exception('Error while getting permission status');
  }
  return response;
}
