import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:location/location.dart';
import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Location location = Location();
  final LocationPlatformMock platform = LocationPlatformMock();
  LocationPlatform.instance = platform;

  tearDown(resetMockitoState);

  group('getLocation', () {
    when(platform.getLocation()).thenAnswer((_) async {
      return LocationData.fromMap(<String, double>{
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
    when(platform.changeSettings(
      accuracy: captureAnyNamed('accuracy'),
      interval: captureAnyNamed('interval'),
      distanceFilter: captureAnyNamed('distanceFilter'),
    ));

    await location.changeSettings();
    final VerificationResult result = verify(platform.changeSettings(
      accuracy: captureAnyNamed('accuracy'),
      interval: captureAnyNamed('interval'),
      distanceFilter: captureAnyNamed('distanceFilter'),
    ));

    expect(result.callCount, 1);
    expect(result.captured[0], LocationAccuracy.high);
    expect(result.captured[1], 1000);
    expect(result.captured[2], 0);
  });

  group('serviceEnabled-requestService', () {
    when(platform.serviceEnabled()).thenAnswer((_) async => true);
    when(platform.requestService()).thenAnswer((_) async => true);

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
    when(platform.hasPermission())
        .thenAnswer((_) async => PermissionStatus.denied);
    when(platform.requestPermission())
        .thenAnswer((_) async => PermissionStatus.denied);

    PermissionStatus receivedPermission = await location.hasPermission();
    expect(receivedPermission, PermissionStatus.denied);

    receivedPermission = await location.requestPermission();
    expect(receivedPermission, PermissionStatus.denied);
  });

  group('onLocationChanged', () {
    StreamController<LocationData> controller;

    setUp(() {
      controller = StreamController<LocationData>();
      when(platform.onLocationChanged)
          .thenAnswer((Invocation invoke) => controller.stream);
    });

    tearDown(() => controller.close());

    test('should receive values', () async {
      controller.add(LocationData.fromMap(<String, double>{
        'latitude': 48.8534,
        'longitude': 2.3488,
      }));
      controller.add(LocationData.fromMap(<String, double>{
        'latitude': 42.8534,
        'longitude': 23.3488,
      }));
      controller.close();

      await expectLater(
        location.onLocationChanged,
        emitsInOrder(
          <dynamic>[
            LocationData.fromMap(<String, double>{
              'latitude': 48.8534,
              'longitude': 2.3488,
            }),
            LocationData.fromMap(<String, double>{
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
