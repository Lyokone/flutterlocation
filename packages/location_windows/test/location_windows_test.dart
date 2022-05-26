import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:location_windows/location_windows.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationWindows', () {
    const kPlatformName = 'Windows';
    late LocationWindows location;
    late List<MethodCall> log;

    setUp(() async {
      location = LocationWindows();

      log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(location.methodChannel, (methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'getPlatformName':
            return kPlatformName;
          default:
            return null;
        }
      });
    });

    test('can be registered', () {
      LocationWindows.registerWith();
      expect(LocationPlatform.instance, isA<LocationWindows>());
    });

    test('getPlatformName returns correct name', () async {
      final name = await location.getPlatformName();
      expect(
        log,
        <Matcher>[isMethodCall('getPlatformName', arguments: null)],
      );
      expect(name, equals(kPlatformName));
    });
  });
}
