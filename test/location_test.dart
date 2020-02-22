import 'dart:async';

import 'package:flutter/services.dart';
import 'package:test/test.dart';
import 'package:location/location.dart';
import 'package:mockito/mockito.dart';

void main() {
  MockMethodChannel methodChannel;
  MockEventChannel eventChannel;
  Location location;

  setUp(() {
    methodChannel = MockMethodChannel();
    eventChannel = MockEventChannel();
    location = Location.private(methodChannel, eventChannel);
  });

  test('getLocation', () async {
    when(methodChannel.invokeMethod<Map<String, double>>('getLocation'))
        .thenAnswer((Invocation invoke) => Future<Map<String, double>>.value({
              "latitude": 48.8534,
              "longitude": 2.3488,
            }));
    var receivedLocation = await location.getLocation();
    expect(receivedLocation.latitude, 48.8534);
    expect(receivedLocation.longitude, 2.3488);
  });

  group('Permission Status', () {
    test('Should convert int to correct Permission Status', () async {
      when(methodChannel.invokeMethod<int>('hasPermission'))
          .thenAnswer((Invocation invoke) => Future<int>.value(0));
      var receivedLocation = await location.hasPermission();
      expect(receivedLocation, PermissionStatus.DENIED);

      when(methodChannel.invokeMethod<int>('hasPermission'))
          .thenAnswer((Invocation invoke) => Future<int>.value(1));
      receivedLocation = await location.hasPermission();
      expect(receivedLocation, PermissionStatus.GRANTED);

      when(methodChannel.invokeMethod<int>('hasPermission'))
          .thenAnswer((Invocation invoke) => Future<int>.value(2));
      receivedLocation = await location.hasPermission();
      expect(receivedLocation, PermissionStatus.DENIED_FOREVER);
    });

    test('Should throw if other message is sent', () async {
      when(methodChannel.invokeMethod<int>('hasPermission'))
          .thenAnswer((Invocation invoke) => Future<int>.value(12));
      try {
        await location.hasPermission();
      } on PlatformException catch (err) {
        expect(err.code, "UNKNOWN_NATIVE_MESSAGE");
      }
    });
  });
}

class MockMethodChannel extends Mock implements MethodChannel {}

class MockEventChannel extends Mock implements EventChannel {}
