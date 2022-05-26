import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:location_platform_interface/messages.pigeon.dart';

/// The Web implementation of [LocationPlatform].
class LocationWeb extends LocationPlatform {
  /// Registers this class as the default instance of [LocationPlatform]
  static void registerWith([Object? registrar]) {
    LocationPlatform.instance = LocationWeb();
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
