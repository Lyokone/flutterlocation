import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:location_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E', () {
    testWidgets('getPlatformName', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Platform Name'));
      await tester.pumpAndSettle();
      final expected = expectedPlatformName();
      await tester.ensureVisible(find.text('Platform Name: $expected'));
    });
  });
}

String expectedPlatformName() {
  if (isWeb) return 'Web';
  if (Platform.isAndroid) return 'Android';
  if (Platform.isIOS) return 'iOS';
  if (Platform.isLinux) return 'Linux';
  if (Platform.isMacOS) return 'MacOS';
  if (Platform.isWindows) return 'Windows';
  throw UnsupportedError('Unsupported platform ${Platform.operatingSystem}');
}

bool get isWeb => identical(0, 0.0);
