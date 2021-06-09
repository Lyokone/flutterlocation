import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:location/location.dart';
import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'location_test.mocks.dart';

// ignore: always_specify_types
@GenerateMocks([Location])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Location location = MockLocation();

  tearDown(resetMockitoState);

  group('getLocation', () {
    when(location.getLocation()).thenAnswer((_) async {
      return LocationData.fromMap(<String, dynamic>{
        'latitude': 48.8534,
        'longitude': 2.3488,
      });
    });

    test('getLocation should convert results correctly', () async {
      final LocationData receivedLocation = await location.getLocation();
      expect(receivedLocation.latitude, 48.8534);
      expect(receivedLocation.longitude, 2.3488);
    });

    test('getLocation should convert to string correctly', () async {
      final LocationData receivedLocation = await location.getLocation();

      expect(receivedLocation.toString(),
          'LocationData<lat: ${receivedLocation.latitude}, long: ${receivedLocation.longitude}>');
    });
  });

  test('changeSettings', () async {
    when(location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000,
      distanceFilter: 0,
    )).thenAnswer((_) async => true);

    await location.changeSettings();
    final VerificationResult result = verify(location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000,
      distanceFilter: 0,
    ));

    expect(result.callCount, 1);
  });

  group('serviceEnabled-requestService', () {
    when(location.serviceEnabled()).thenAnswer((_) async => true);
    when(location.requestService()).thenAnswer((_) async => true);

    test('serviceEnabled', () async {
      final bool result = await location.serviceEnabled();
      expect(result, isTrue);
    });

    test('requestService', () async {
      final bool result = await location.requestService();
      expect(result, isTrue);
    });
  });

  test('hasPermission', () async {
    when(location.hasPermission())
        .thenAnswer((_) async => PermissionStatus.denied);
    when(location.requestPermission())
        .thenAnswer((_) async => PermissionStatus.denied);

    PermissionStatus receivedPermission = await location.hasPermission();
    expect(receivedPermission, PermissionStatus.denied);

    receivedPermission = await location.requestPermission();
    expect(receivedPermission, PermissionStatus.denied);
  });

  group('onLocationChanged', () {
    late StreamController<LocationData> controller;

    setUp(() {
      controller = StreamController<LocationData>();
      when(location.onLocationChanged)
          .thenAnswer((Invocation invoke) => controller.stream);
    });

    tearDown(() => controller.close());

    test('should receive values', () async {
      controller.add(LocationData.fromMap(<String, dynamic>{
        'latitude': 48.8534,
        'longitude': 2.3488,
      }));
      controller.add(LocationData.fromMap(<String, dynamic>{
        'latitude': 42.8534,
        'longitude': 23.3488,
      }));
      controller.close();

      await expectLater(
        location.onLocationChanged,
        emitsInOrder(
          <dynamic>[
            LocationData.fromMap(<String, dynamic>{
              'latitude': 48.8534,
              'longitude': 2.3488,
            }),
            LocationData.fromMap(<String, dynamic>{
              'latitude': 42.8534,
              'longitude': 23.3488,
            }),
            emitsDone,
          ],
        ),
      );
    });
  });
}

class LocationPlatformMock extends Mock
    with MockPlatformInterfaceMixin
    implements LocationPlatform {}
