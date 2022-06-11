import 'package:location_platform_interface/location_platform_interface.dart';

/// The MacOS implementation of [LocationPlatform].
class LocationMacOS {
  /// Registers this class as the default instance of [LocationPlatform]
  static void registerWith() {
    LocationPlatform.instance = MethodChannelLocation();
  }
}
