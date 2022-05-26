import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_android/location_android.dart';
import 'package:location_platform_interface/location_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationAndroid', () {
    const kPlatformName = 'Android';
    late LocationAndroid location;
    late List<MethodCall> log;

    setUp(() async {
      location = LocationAndroid();

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
      LocationAndroid.registerWith();
      expect(LocationPlatform.instance, isA<LocationAndroid>());
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
