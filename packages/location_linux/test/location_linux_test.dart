import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_linux/location_linux.dart';
import 'package:location_platform_interface/location_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationLinux', () {
    const kPlatformName = 'Linux';
    late LocationLinux location;
    late List<MethodCall> log;

    setUp(() async {
      location = LocationLinux();

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
      LocationLinux.registerWith();
      expect(LocationPlatform.instance, isA<LocationLinux>());
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
