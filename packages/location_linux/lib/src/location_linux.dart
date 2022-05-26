import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:location_platform_interface/messages.pigeon.dart';

/// The Linux implementation of [LocationPlatform].
class LocationLinux extends LocationPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('location_linux');

  /// Registers this class as the default instance of [LocationPlatform]
  static void registerWith() {
    LocationPlatform.instance = LocationLinux();
  }

  @override
  Future<LocationData?> getLocation() {
    // TODO: implement getLocation
    throw UnimplementedError();
  }

  @override
  // TODO: implement onLocationChanged
  Stream<LocationData?> get onLocationChanged => throw UnimplementedError();
}
