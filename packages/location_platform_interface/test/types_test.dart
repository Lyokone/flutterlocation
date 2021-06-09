import 'package:flutter_test/flutter_test.dart';
import 'package:location_platform_interface/location_platform_interface.dart';

void main() {
  group('LocationData', () {
    test('LocationData should be correctly converted to string', () {
      final LocationData locationData = LocationData.fromMap(
          <String, dynamic>{'latitude': 42, 'longitude': 2});
      expect(locationData.toString(),
          'LocationData<lat: ${locationData.latitude}, long: ${locationData.longitude}>');
    });

    test('LocationData should be equal if all parameters are equals', () {
      final LocationData locationData = LocationData.fromMap(<String, dynamic>{
        'latitude': 42,
        'longitude': 2,
        'accuracy': 2,
        'altitude': 2,
        'speed': 2,
        'speed_accuracy': 2,
        'heading': 2,
        'time': 2
      });
      final LocationData otherLocationData =
          LocationData.fromMap(<String, dynamic>{
        'latitude': 42,
        'longitude': 2,
        'accuracy': 2,
        'altitude': 2,
        'speed': 2,
        'speed_accuracy': 2,
        'heading': 2,
        'time': 2
      });

      expect(otherLocationData == locationData, true);
      expect(otherLocationData.hashCode == locationData.hashCode, true);
    });

    test('LocationData should be different if one parameters is different', () {
      final LocationData locationData = LocationData.fromMap(<String, dynamic>{
        'latitude': 42,
        'longitude': 2,
        'accuracy': 2,
        'altitude': 22,
        'speed': 2,
        'speed_accuracy': 2,
        'heading': 2,
        'time': 2
      });
      final LocationData otherLocationData =
          LocationData.fromMap(<String, dynamic>{
        'latitude': 42,
        'longitude': 2,
        'accuracy': 2,
        'altitude': 2,
        'speed': 2,
        'speed_accuracy': 2,
        'heading': 2,
        'time': 2
      });

      expect(otherLocationData == locationData, false);
      expect(otherLocationData.hashCode == locationData.hashCode, false);
    });
  });
}
