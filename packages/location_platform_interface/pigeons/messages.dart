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
    this.askForPermission,
    this.rationaleMessageForPermissionRequest,
    this.useGooglePlayServices,
    this.askForGooglePlayServices,
    this.askForGPS,
    this.fallbackToGPS,
    this.ignoreLastKnownPosition,
    this.expirationDuration,
    this.setExpirationTime,
    this.setFastestInterval,
    this.setInterval,
    this.setMaxWaitTime,
    this.setNumUpdates,
    this.setAccuracy,
    this.setSmallestDisplacement,
    this.setWaitForAccurateLocation,
  });

  bool? askForPermission;
  String? rationaleMessageForPermissionRequest;
  bool? useGooglePlayServices;
  bool? askForGooglePlayServices;
  bool? askForGPS;
  bool? fallbackToGPS;
  bool? ignoreLastKnownPosition;
  double? expirationDuration;
  double? setExpirationTime;
  double? setFastestInterval;
  double? setInterval;
  double? setMaxWaitTime;
  int? setNumUpdates;
  LocationAccuracy? setAccuracy;
  double? setSmallestDisplacement;
  bool? setWaitForAccurateLocation;
}

@HostApi()
abstract class LocationHostApi {
  @async
  LocationData getLocation();

  bool setLocationSettings(LocationSettings settings);
}
