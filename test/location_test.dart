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
}

class MockMethodChannel extends Mock implements MethodChannel {}

class MockEventChannel extends Mock implements EventChannel {}
