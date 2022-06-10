import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:location_platform_interface/messages.pigeon.dart';

/// The Web implementation of [LocationPlatform].
class LocationWeb extends LocationPlatform {
  /// Registers this class as the default instance of [LocationPlatform]
  static void registerWith([Object? registrar]) {
    LocationPlatform.instance = LocationWeb();
  }

  @override
  Future<LocationData?> getLocation({LocationSettings? settings}) {
    // TODO: implement getLocation
    throw UnimplementedError();
  }

  @override
  // TODO: implement onLocationChanged
  Stream<LocationData?> get onLocationChanged => throw UnimplementedError();

  @override
  Future<PermissionStatus?> getPermissionStatus() {
    // TODO: implement getPermissionStatus
    throw UnimplementedError();
  }

  @override
  Future<bool?> isGPSEnabled() {
    // TODO: implement isGPSEnabled
    throw UnimplementedError();
  }

  @override
  Future<bool?> isNetworkEnabled() {
    // TODO: implement isNetworkEnabled
    throw UnimplementedError();
  }

  @override
  Future<PermissionStatus?> requestPermission() {
    // TODO: implement requestPermission
    throw UnimplementedError();
  }

  @override
  Future<bool?> setLocationSettings(LocationSettings settings) {
    // TODO: implement setLocationSettings
    throw UnimplementedError();
  }
}
