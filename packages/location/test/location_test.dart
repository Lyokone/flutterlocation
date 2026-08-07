import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:location/location.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'location_test.mocks.dart';

@GenerateMocks([Location])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockLocation = MockLocation();
  Location.instance = mockLocation;
  final location = Location();

  tearDown(resetMockitoState);

  test(
    'changeSettings should call the correct underlying instance',
    () async {
      when(location.changeSettings()).thenAnswer((_) => Future.value(true));

      await location.changeSettings();
      verify(mockLocation.changeSettings()).called(1);
    },
  );

  test(
    'isBackgroundModeEnabled should call the correct underlying instance',
    () async {
      when(location.isBackgroundModeEnabled())
          .thenAnswer((_) => Future.value(true));

      await location.isBackgroundModeEnabled();
      verify(mockLocation.isBackgroundModeEnabled()).called(1);
    },
  );

  test(
    'enableBackgroundMode should call the correct underlying instance',
    () async {
      when(location.enableBackgroundMode())
          .thenAnswer((_) => Future.value(true));

      await location.enableBackgroundMode();
      verify(mockLocation.enableBackgroundMode()).called(1);
    },
  );

  test('getLocation should call the correct underlying instance', () async {
    when(location.getLocation()).thenAnswer((_) => Future.value(
        LocationData.fromMap({'latitude': 42.0, 'longitude': 2.0})));

    await location.getLocation();
    verify(mockLocation.getLocation()).called(1);
  });

  test(
    'getLastKnownLocation should call the correct underlying instance',
    () async {
      when(location.getLastKnownLocation()).thenAnswer((_) => Future.value(
          LocationData.fromMap({'latitude': 42.0, 'longitude': 2.0})));

      await location.getLastKnownLocation();
      verify(mockLocation.getLastKnownLocation()).called(1);
    },
  );

  test(
    'hasPermission should call the correct underlying instance',
    () async {
      when(location.hasPermission())
          .thenAnswer((_) => Future.value(PermissionStatus.granted));

      await location.hasPermission();
      verify(mockLocation.hasPermission()).called(1);
    },
  );

  test(
    'requestPermission should call the correct underlying instance',
    () async {
      when(location.requestPermission())
          .thenAnswer((_) => Future.value(PermissionStatus.granted));

      await location.requestPermission();
      verify(mockLocation.requestPermission()).called(1);
    },
  );

  test('serviceEnabled should call the correct underlying instance', () async {
    when(location.serviceEnabled()).thenAnswer((_) => Future.value(true));

    await location.serviceEnabled();
    verify(mockLocation.serviceEnabled()).called(1);
  });

  test('requestService should call the correct underlying instance', () async {
    when(location.requestService()).thenAnswer((_) => Future.value(true));

    await location.requestService();
    verify(mockLocation.requestService()).called(1);
  });

  test(
    'setActivityType should call the correct underlying instance',
    () async {
      when(location.setActivityType(LocationActivityType.fitness))
          .thenAnswer((_) => Future.value(LocationActivityType.fitness));

      final applied =
          await location.setActivityType(LocationActivityType.fitness);
      expect(applied, LocationActivityType.fitness);
      verify(mockLocation.setActivityType(LocationActivityType.fitness))
          .called(1);
    },
  );

  test(
    'changeNotificationOptions should call the correct underlying instance',
    () async {
      when(location.changeNotificationOptions())
          .thenAnswer((_) => Future.value());

      await location.changeNotificationOptions();
      verify(mockLocation.changeNotificationOptions()).called(1);
    },
  );

  group('onLocationChanged', () {
    late StreamController<LocationData> controller;

    setUp(() {
      controller = StreamController<LocationData>();
      when(location.onLocationChanged).thenAnswer((_) => controller.stream);
    });

    tearDown(() => controller.close());

    test('should receive values', () async {
      controller
        ..add(
          LocationData.fromMap(<String, dynamic>{
            'latitude': 48.8534,
            'longitude': 2.3488,
          }),
        )
        ..add(
          LocationData.fromMap(<String, dynamic>{
            'latitude': 42.8534,
            'longitude': 23.3488,
          }),
        );
      unawaited(controller.close());

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

  group('onLocationUpdatesPaused', () {
    late StreamController<bool> controller;

    setUp(() {
      controller = StreamController<bool>();
      when(location.onLocationUpdatesPaused)
          .thenAnswer((_) => controller.stream);
    });

    tearDown(() => controller.close());

    test('should receive pause and resume values', () async {
      controller
        ..add(true)
        ..add(false);
      unawaited(controller.close());

      await expectLater(
        location.onLocationUpdatesPaused,
        emitsInOrder(<dynamic>[true, false, emitsDone]),
      );
    });
  });
}
