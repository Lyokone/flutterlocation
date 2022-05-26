import 'package:flutter_test/flutter_test.dart';
import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:location_web/location_web.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationWeb', () {
    const kPlatformName = 'Web';
    late LocationWeb location;

    setUp(() async {
      location = LocationWeb();
    });

    test('can be registered', () {
      LocationWeb.registerWith();
      expect(LocationPlatform.instance, isA<LocationWeb>());
    });

    test('getPlatformName returns correct name', () async {
      final name = await location.getPlatformName();
      expect(name, equals(kPlatformName));
    });
  });
}
