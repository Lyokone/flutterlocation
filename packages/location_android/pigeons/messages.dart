import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/android_location.pigeon.dart',
    dartTestOut: 'test/android_location.pigeon.dart',
    javaOut:
        'android/src/main/java/com/lyokone/location/GeneratedAndroidLocation.java',
    javaOptions: JavaOptions(
      package: 'com.lyokone.location',
      className: 'GeneratedAndroidLocation',
    ),
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

/// Status of a permission request to use location services.
enum PermissionStatus {
  /// The permission to use location services has been granted for high accuracy.
  granted,

  /// The permission has been granted but for low accuracy. Only valid on iOS 14+.
  grantedLimited,

  /// The permission to use location services has been denied by the user. May
  /// have been denied forever on iOS.
  denied,

  /// The permission to use location services has been denied forever by the
  /// user. No dialog will be displayed on permission request.
  deniedForever
}

class LocationSettings {
  LocationSettings({
    this.askForPermission = true,
    this.rationaleMessageForPermissionRequest =
        'The app needs to access your location',
    this.rationaleMessageForGPSRequest =
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
    this.acceptableAccuracy,
    this.accuracy = LocationAccuracy.high,
    this.smallestDisplacement = 0,
    this.waitForAccurateLocation = true,
  });

  bool askForPermission;
  String rationaleMessageForPermissionRequest;
  String rationaleMessageForGPSRequest;
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
  double? acceptableAccuracy;
}

@HostApi()
abstract class LocationHostApi {
  @async
  LocationData getLocation(LocationSettings? settings);

  bool setLocationSettings(LocationSettings settings);

  int getPermissionStatus();
}
