import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.pigeon.dart',
    dartTestOut: 'test/test.pigeon.dart',
    javaOut:
        '../location_android/android/src/main/java/com/lyokone/location/GeneratedAndroidLocation.java',
    javaOptions: JavaOptions(
      package: 'com.lyokone.location',
      className: 'GeneratedAndroidLocation',
    ),
    objcHeaderOut: '../location_ios/ios/Classes/messages.g.h',
    objcSourceOut: '../location_ios/ios/Classes/messages.g.m',
  ),
)
class PigeonLocationData {
  double? latitude;
  double? longitude;
  double? accuracy;
  double? altitude;
  double? bearing;
  double? bearingAccuracyDegrees;
  double? elaspedRealTimeNanos;
  double? elaspedRealTimeUncertaintyNanos;
  int? satellites;
  double? speed;
  double? speedAccuracy;
  double? time;
  double? verticalAccuracy;
  bool? isMock;
}

enum PigeonLocationAccuracy { powerSave, low, balanced, high, navigation }

class PigeonLocationSettings {
  PigeonLocationSettings({
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
    this.accuracy = PigeonLocationAccuracy.high,
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
  PigeonLocationAccuracy accuracy;
  double smallestDisplacement;
  bool waitForAccurateLocation;
  double? acceptableAccuracy;
}

@HostApi()
abstract class LocationHostApi {
  @async
  PigeonLocationData getLocation(PigeonLocationSettings? settings);

  bool setLocationSettings(PigeonLocationSettings settings);

  int getPermissionStatus();

  @async
  int requestPermission();

  bool isGPSEnabled();

  bool isNetworkEnabled();
}
