import 'package:flutter/foundation.dart';
import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:location_platform_interface/messages.pigeon.dart';

/// The Android implementation of [LocationPlatform].
class LocationAndroid extends LocationPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final api = LocationHostApi();

  /// Registers this class as the default instance of [LocationPlatform]
  static void registerWith() {
    LocationPlatform.instance = LocationAndroid();
  }

  @override
  Future<LocationData?> getLocation() {
    return api.getLocation();
  }

  @override
  Stream<LocationData?> get onLocationChanged {
    return LocationPlatform.instance.onLocationChanged;
  }
}
