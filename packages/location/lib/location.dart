import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:location_platform_interface/messages.pigeon.dart';

export 'package:location_platform_interface/messages.pigeon.dart'
    show LocationData;

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
