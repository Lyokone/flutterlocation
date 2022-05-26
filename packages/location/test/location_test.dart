import 'package:flutter_test/flutter_test.dart';
import 'package:location/location.dart';
import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLocationPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements LocationPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Location', () {
    late LocationPlatform locationPlatform;

    setUp(() {
      locationPlatform = MockLocationPlatform();
      LocationPlatform.instance = locationPlatform;
    });

    group('getPlatformName', () {
      test('returns correct name when platform implementation exists',
          () async {
        const platformName = '__test_platform__';
        when(
          () => locationPlatform.getPlatformName(),
        ).thenAnswer((_) async => platformName);

        final actualPlatformName = await getLocation();
        expect(actualPlatformName, equals(platformName));
      });

      test('throws exception when platform implementation is missing',
          () async {
        when(
          () => locationPlatform.getPlatformName(),
        ).thenAnswer((_) async => null);

        expect(getLocation, throwsException);
      });
    });
  });
}
