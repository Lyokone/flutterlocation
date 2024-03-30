import 'package:flutter_test/flutter_test.dart';
import 'package:location_platform_interface/location_platform_interface.dart';

void main() {
  group('LocationData', () {
    test('LocationData should be correctly converted to string', () {
      final locationData = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
      });
      expect(
        locationData.toString(),
        'LocationData<lat: ${locationData.latitude}, long: ${locationData.longitude}>',
      );
    });

    test('LocationData should be equal if all parameters are equals', () {
      final locationData = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'accuracy': 2.0,
        'altitude': 2.0,
        'speed': 2.0,
        'speed_accuracy': 2.0,
        'heading': 2.0,
        'time': 2.0,
      });
      final otherLocationData = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'accuracy': 2.0,
        'altitude': 2.0,
        'speed': 2.0,
        'speed_accuracy': 2.0,
        'heading': 2.0,
        'time': 2.0,
      });

      expect(otherLocationData == locationData, true);
      expect(otherLocationData.hashCode == locationData.hashCode, true);
    });

    test('LocationData should be different if one parameters is different', () {
      final locationData = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'accuracy': 2.0,
        'altitude': 22.0,
        'speed': 2.0,
        'speed_accuracy': 2.0,
        'heading': 2.0,
        'time': 2.0,
      });
      final otherLocationData = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'accuracy': 2.0,
        'altitude': 2.0,
        'speed': 2.0,
        'speed_accuracy': 2.0,
        'heading': 2.0,
        'time': 2.0,
      });

      expect(otherLocationData == locationData, false);
      expect(otherLocationData.hashCode == locationData.hashCode, false);
    });
  });

  group('$AndroidNotificationData', () {
    test('AndroidNotificationData should be correctly converted to string', () {
      final androidNotificationData =
          AndroidNotificationData.fromMap(<String, dynamic>{
        'channelId': 'test-id',
        'notificationId': 2,
      });
      expect(
        androidNotificationData.toString(),
        'AndroidNotificationData<channelId: test-id, notificationId: 2>',
      );
    });

    test('AndroidNotificationData should be equal if all parameters are equals',
        () {
      final androidNotificationData = AndroidNotificationData.fromMap(
        <String, dynamic>{
          'channelId': 'test-id',
          'notificationId': 2,
        },
      );
      final otherAndroidNotificationData = AndroidNotificationData.fromMap(
        <String, dynamic>{
          'channelId': 'test-id',
          'notificationId': 2,
        },
      );

      expect(otherAndroidNotificationData == androidNotificationData, true);
      expect(
        otherAndroidNotificationData.hashCode ==
            androidNotificationData.hashCode,
        true,
      );
    });

    test('LocationData should be different if one parameters is different', () {
      final androidNotificationData = AndroidNotificationData.fromMap(
        <String, dynamic>{
          'channelId': 'test-id',
          'notificationId': 2,
        },
      );
      final otherAndroidNotificationData = AndroidNotificationData.fromMap(
        <String, dynamic>{
          'channelId': 'test-id',
          'notificationId': 3,
        },
      );

      expect(otherAndroidNotificationData == androidNotificationData, false);
      expect(
        otherAndroidNotificationData.hashCode ==
            androidNotificationData.hashCode,
        false,
      );
    });
  });
}
