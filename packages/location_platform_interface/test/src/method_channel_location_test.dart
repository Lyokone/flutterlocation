import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_platform_interface/src/method_channel_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const kPlatformName = 'platformName';

  group('$MethodChannelLocation', () {
    late MethodChannelLocation methodChannelLocation;
    final log = <MethodCall>[];

    setUp(() async {
      methodChannelLocation = MethodChannelLocation()
        ..methodChannel.setMockMethodCallHandler((MethodCall methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'getPlatformName':
              return kPlatformName;
            default:
              return null;
          }
        });
    });

    tearDown(log.clear);

    test('getPlatformName', () async {
      final platformName = await methodChannelLocation.getPlatformName();
      expect(
        log,
        <Matcher>[isMethodCall('getPlatformName', arguments: null)],
      );
      expect(platformName, equals(kPlatformName));
    });
  });
}
