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

    test('toJson exposes every field of LocationData', () {
      final locationData = LocationData.fromJson(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'accuracy': 3.0,
        'verticalAccuracy': 4.0,
        'altitude': 5.0,
        'speed': 6.0,
        'speedAccuracy': 7.0,
        'heading': 8.0,
        'time': 9.0,
        'isMock': true,
        'isProducedByAccessory': true,
        'headingAccuracy': 10.0,
        'elapsedRealtimeNanos': 11.0,
        'elapsedRealtimeUncertaintyNanos': 12.0,
        'satelliteNumber': 13,
        'provider': 'gps',
      });

      expect(locationData.toJson(), <String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'accuracy': 3.0,
        'verticalAccuracy': 4.0,
        'altitude': 5.0,
        'speed': 6.0,
        'speedAccuracy': 7.0,
        'heading': 8.0,
        'time': 9.0,
        'isMock': true,
        'isProducedByAccessory': true,
        'headingAccuracy': 10.0,
        'elapsedRealtimeNanos': 11.0,
        'elapsedRealtimeUncertaintyNanos': 12.0,
        'satelliteNumber': 13,
        'provider': 'gps',
      });
    });

    test('fromJson(toJson) round-trips with all fields set', () {
      final locationData = LocationData.fromJson(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'accuracy': 3.0,
        'verticalAccuracy': 4.0,
        'altitude': 5.0,
        'speed': 6.0,
        'speedAccuracy': 7.0,
        'heading': 8.0,
        'time': 9.0,
        'isMock': true,
        'isProducedByAccessory': true,
        'headingAccuracy': 10.0,
        'elapsedRealtimeNanos': 11.0,
        'elapsedRealtimeUncertaintyNanos': 12.0,
        'satelliteNumber': 13,
        'provider': 'gps',
      });

      final roundTripped = LocationData.fromJson(locationData.toJson());

      expect(roundTripped, locationData);
      expect(roundTripped.hashCode, locationData.hashCode);
    });

    test('fromJson(toJson) round-trips with null fields', () {
      final locationData = LocationData.fromJson(<String, dynamic>{});

      expect(LocationData.fromJson(locationData.toJson()), locationData);
    });

    test('copyWith replaces only the provided fields', () {
      final locationData = LocationData.fromJson(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'provider': 'gps',
      });

      final updated = locationData.copyWith(
        longitude: 3.5,
        provider: 'network',
        isProducedByAccessory: true,
      );

      expect(updated.latitude, 42.0);
      expect(updated.longitude, 3.5);
      expect(updated.provider, 'network');
      expect(updated.isProducedByAccessory, true);
    });

    test('LocationData parses isProducedByAccessory from the platform map', () {
      final accessoryLocation = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'isProducedByAccessory': 1,
      });
      expect(accessoryLocation.isProducedByAccessory, true);

      final deviceLocation = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'isProducedByAccessory': 0,
      });
      expect(deviceLocation.isProducedByAccessory, false);

      // Defaults to false when the platform omits the key (Android/web).
      final missingLocation = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
      });
      expect(missingLocation.isProducedByAccessory, false);
    });

    test('LocationData differs when isProducedByAccessory differs', () {
      final accessoryLocation = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'isProducedByAccessory': 1,
      });
      final deviceLocation = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'isProducedByAccessory': 0,
      });

      expect(accessoryLocation == deviceLocation, false);
      expect(accessoryLocation.hashCode == deviceLocation.hashCode, false);
      expect(accessoryLocation.toString(), contains('accessory'));
    });
  });

  group('$AndroidNotificationData', () {
    test('AndroidNotificationData should be correctly converted to string', () {
      final androidNotificationData = AndroidNotificationData.fromMap(
        <String, dynamic>{'channelId': 'test-id', 'notificationId': 2},
      );
      expect(
        androidNotificationData.toString(),
        'AndroidNotificationData<channelId: test-id, notificationId: 2>',
      );
    });

    test(
      'AndroidNotificationData should be equal if all parameters are equals',
      () {
        final androidNotificationData = AndroidNotificationData.fromMap(
          <String, dynamic>{'channelId': 'test-id', 'notificationId': 2},
        );
        final otherAndroidNotificationData = AndroidNotificationData.fromMap(
          <String, dynamic>{'channelId': 'test-id', 'notificationId': 2},
        );

        expect(otherAndroidNotificationData == androidNotificationData, true);
        expect(
          otherAndroidNotificationData.hashCode ==
              androidNotificationData.hashCode,
          true,
        );
      },
    );

    test('LocationData should be different if one parameters is different', () {
      final androidNotificationData = AndroidNotificationData.fromMap(
        <String, dynamic>{'channelId': 'test-id', 'notificationId': 2},
      );
      final otherAndroidNotificationData = AndroidNotificationData.fromMap(
        <String, dynamic>{'channelId': 'test-id', 'notificationId': 3},
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
