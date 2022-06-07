import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/messages.pigeon.dart',
    dartTestOut: 'test/test.pigeon.dart',
  ),
)
class LocationData {
  LocationData(this.latitude, this.longitude);

  double latitude;
  double longitude;
}

enum LocationAccuracy {
  /// To request best accuracy possible with zero additional power consumption,
  powerSave,

  /// To request "city" level accuracy
  low,

  ///  To request "block" level accuracy
  balanced,

  /// To request the most accurate locations available
  high,

  /// To request location for navigation usage (affect only iOS)
  navigation
}

class LocationSettings {
  LocationSettings({
    this.askForPermission = true,
    this.rationaleMessageForPermissionRequest =
        'The app needs to access your location',
    this.useGooglePlayServices = true,
    this.askForGooglePlayServices = false,
    this.askForGPS = true,
    this.fallbackToGPS = true,
    this.ignoreLastKnownPosition = false,
    this.expirationDuration,
    this.expirationTime,
    this.fastestInterval = 500,
    this.interval = 1000,
    this.maxWaitTime,
    this.numUpdates,
    this.accuracy = LocationAccuracy.high,
    this.smallestDisplacement = 0,
    this.waitForAccurateLocation = true,
  });

  bool askForPermission;
  String rationaleMessageForPermissionRequest;
  bool useGooglePlayServices;
  bool askForGooglePlayServices;
  bool askForGPS;
  bool fallbackToGPS;
  bool ignoreLastKnownPosition;
  double? expirationDuration;
  double? expirationTime;
  double fastestInterval;
  double interval;
  double? maxWaitTime;
  int? numUpdates;
  LocationAccuracy accuracy;
  double smallestDisplacement;
  bool waitForAccurateLocation;
}

@HostApi()
abstract class LocationHostApi {
  @async
  LocationData getLocation();

  bool setLocationSettings(LocationSettings settings);
}
