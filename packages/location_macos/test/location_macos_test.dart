import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_macos/location_macos.dart';
import 'package:location_platform_interface/location_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationMacOS', () {
    const kPlatformName = 'MacOS';
    late LocationMacOS location;
    late List<MethodCall> log;

    setUp(() async {
      location = LocationMacOS();

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
      LocationMacOS.registerWith();
      expect(LocationPlatform.instance, isA<LocationMacOS>());
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
