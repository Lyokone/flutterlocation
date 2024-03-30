import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'method_channel_location_test.mocks.dart';

@GenerateMocks([EventChannel])
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannel? methodChannel;
  MockEventChannel? eventChannel;
  late MethodChannelLocation location;

  final log = <MethodCall>[];

  setUp(() {
    methodChannel = const MethodChannel('lyokone/location');
    eventChannel = MockEventChannel();
    location = MethodChannelLocation.private(methodChannel, eventChannel);

    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      methodChannel!,
      (methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'getLocation':
            return <String, dynamic>{
              'latitude': 48.8534,
              'longitude': 2.3488,
            };
          case 'changeSettings':
            return 1;
          case 'serviceEnabled':
            return 1;
          case 'requestService':
            return 1;
          default:
            return '';
        }
      },
    );

    log.clear();
  });

  group('getLocation', () {
    test('getLocation should convert results correctly', () async {
      final receivedLocation = await location.getLocation();
      expect(receivedLocation.latitude, 48.8534);
      expect(receivedLocation.longitude, 2.3488);
    });
  });

  test('changeSettings passes parameters correctly', () async {
    await location.changeSettings();
    expect(log, <Matcher>[
      isMethodCall(
        'changeSettings',
        arguments: <String, dynamic>{
          'accuracy': LocationAccuracy.high.index,
          'interval': 1000,
          'distanceFilter': 0,
        },
      ),
    ]);
  });

  group('Service Status', () {
    test('serviceEnabled should convert results correctly', () async {
      final result = await location.serviceEnabled();
      expect(result, true);
    });

    test('requestService should convert to string correctly', () async {
      final result = await location.requestService();
      expect(result, true);
    });
  });

  group('Permission Status', () {
    test('Should convert int to correct Permission Status', () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannel!,
        (methodCall) async {
          return 0;
        },
      );
      var receivedPermission = await location.hasPermission();
      expect(receivedPermission, PermissionStatus.denied);
      receivedPermission = await location.requestPermission();
      expect(receivedPermission, PermissionStatus.denied);

      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannel!,
        (methodCall) async {
          return 1;
        },
      );
      receivedPermission = await location.hasPermission();
      expect(receivedPermission, PermissionStatus.granted);
      receivedPermission = await location.requestPermission();
      expect(receivedPermission, PermissionStatus.granted);

      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannel!,
        (methodCall) async {
          return 2;
        },
      );
      receivedPermission = await location.hasPermission();
      expect(receivedPermission, PermissionStatus.deniedForever);
      receivedPermission = await location.requestPermission();
      expect(receivedPermission, PermissionStatus.deniedForever);

      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannel!,
        (methodCall) async {
          return 3;
        },
      );
      receivedPermission = await location.hasPermission();
      expect(receivedPermission, PermissionStatus.grantedLimited);
      receivedPermission = await location.requestPermission();
      expect(receivedPermission, PermissionStatus.grantedLimited);
    });

    test('Should throw if other message is sent', () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannel!,
        (methodCall) async {
          return 12;
        },
      );
      try {
        await location.hasPermission();
      } on PlatformException catch (err) {
        expect(err.code, 'UNKNOWN_NATIVE_MESSAGE');
      }
      try {
        await location.requestPermission();
      } on PlatformException catch (err) {
        expect(err.code, 'UNKNOWN_NATIVE_MESSAGE');
      }
    });
  });

  group('Location Updates', () {
    late StreamController<Map<String, dynamic>> controller;

    setUp(() {
      controller = StreamController<Map<String, dynamic>>();
      when(eventChannel!.receiveBroadcastStream())
          .thenAnswer((invoke) => controller.stream);
    });

    tearDown(() {
      controller.close();
    });

    test('call receiveBrodcastStream once', () {
      location
        ..onLocationChanged
        ..onLocationChanged
        ..onLocationChanged;
      verify(eventChannel!.receiveBroadcastStream()).called(1);
    });

    test('should receive values', () async {
      final queue = StreamQueue<LocationData>(location.onLocationChanged);

      controller.add(<String, dynamic>{
        'latitude': 48.8534,
        'longitude': 2.3488,
      });
      var data = await queue.next;
      expect(data.latitude, 48.8534);
      expect(data.longitude, 2.3488);

      controller.add(<String, dynamic>{
        'latitude': 42.8534,
        'longitude': 23.3488,
      });
      data = await queue.next;
      expect(data.latitude, 42.8534);
      expect(data.longitude, 23.3488);
    });
  });
}
