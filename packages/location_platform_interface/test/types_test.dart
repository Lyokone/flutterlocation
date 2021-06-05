import 'package:flutter_test/flutter_test.dart';
import 'package:location_platform_interface/location_platform_interface.dart';

void main() {
  group('LocationData', () {
    test('LocationData should be correctly converted to string', () {
      final LocationData locationData = LocationData.fromMap(
          <String, dynamic>{'latitude': 42.0, 'longitude': 2.0});
      expect(locationData.toString(),
          'LocationData<lat: ${locationData.latitude}, long: ${locationData.longitude}>');
    });

    test('LocationData should be equal if all parameters are equals', () {
      final LocationData locationData = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'accuracy': 2.0,
        'altitude': 2.0,
        'speed': 2.0,
        'speed_accuracy': 2.0,
        'heading': 2.0,
        'time': 2.0
      });
      final LocationData otherLocationData =
          LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'accuracy': 2.0,
        'altitude': 2.0,
        'speed': 2.0,
        'speed_accuracy': 2.0,
        'heading': 2.0,
        'time': 2.0
      });

      expect(otherLocationData == locationData, true);
      expect(otherLocationData.hashCode == locationData.hashCode, true);
    });

    test('LocationData should be different if one parameters is different', () {
      final LocationData locationData = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'accuracy': 2.0,
        'altitude': 22.0,
        'speed': 2.0,
        'speed_accuracy': 2.0,
        'heading': 2.0,
        'time': 2.0
      });
      final LocationData otherLocationData =
          LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'accuracy': 2.0,
        'altitude': 2.0,
        'speed': 2.0,
        'speed_accuracy': 2.0,
        'heading': 2.0,
        'time': 2.0
      });

      expect(otherLocationData == locationData, false);
      expect(otherLocationData.hashCode == locationData.hashCode, false);
    });
  });
}
