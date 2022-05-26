import 'package:flutter_test/flutter_test.dart';
import 'package:location_platform_interface/location_platform_interface.dart';

class LocationMock extends LocationPlatform {
  static const mockPlatformName = 'Mock';

  @override
  Future<String?> getPlatformName() async => mockPlatformName;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('LocationPlatformInterface', () {
    late LocationPlatform locationPlatform;

    setUp(() {
      locationPlatform = LocationMock();
      LocationPlatform.instance = locationPlatform;
    });

    group('getPlatformName', () {
      test('returns correct name', () async {
        expect(
          await LocationPlatform.instance.getPlatformName(),
          equals(LocationMock.mockPlatformName),
        );
      });
    });
  });
}
