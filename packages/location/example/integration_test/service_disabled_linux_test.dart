import 'package:example/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Linux-only variant of service_disabled_test.dart -- see
/// get_location_linux_test.dart's doc comment for why this is plain
/// `testWidgets` rather than Patrol.
///
/// The CI job stops the fake GeoClue2 service before running this file, so
/// the plugin can't reach it at all (see `.github/workflows/e2e.yaml`) --
/// this directly targets the hang-class bugs fixed this session (#728,
/// #1020, #926): `getLocation()` must resolve with a clean error within a
/// bounded time, not hang forever.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'getLocation() reports a clean error instead of hanging when '
      'GeoClue2 is unreachable', (tester) async {
    await tester.pumpWidget(const app.MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('serviceCheckButton')));
    final serviceDeadline = DateTime.now().add(const Duration(seconds: 15));
    String serviceText;
    do {
      if (DateTime.now().isAfter(serviceDeadline)) {
        fail('serviceEnabled() did not resolve within 15s');
      }
      await tester.pump(const Duration(milliseconds: 250));
      serviceText = tester
              .widget<Text>(find.byKey(const Key('serviceEnabledText')))
              .data ??
          '';
    } while (serviceText.contains('unknown'));
    expect(
      serviceText,
      contains('false'),
      reason: 'This test needs the fake GeoClue2 service stopped before it '
          'runs -- see the file doc comment.',
    );

    await tester.tap(find.byKey(const Key('getLocationButton')));
    final locationDeadline = DateTime.now().add(const Duration(seconds: 20));
    String locationText;
    do {
      if (DateTime.now().isAfter(locationDeadline)) {
        fail('getLocation() did not resolve within 20s (hung instead of '
            'erroring)');
      }
      await tester.pump(const Duration(milliseconds: 250));
      locationText =
          tester.widget<Text>(find.byKey(const Key('getLocationText'))).data ??
              '';
    } while (locationText.contains('unknown'));

    expect(
      locationText.contains('SERVICE_STATUS_DISABLED') ||
          locationText.contains('SERVICE_STATUS_ERROR'),
      isTrue,
      reason: 'Expected a clean service-unavailable error, got: $locationText',
    );
  });
}
