import 'package:example/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_config.dart';

/// Linux-only variant of get_location_test.dart. Plain `testWidgets`, not
/// Patrol: `patrol_cli` has no support for `-d linux` at all ("Device linux
/// is not attached", confirmed via CI) -- Linux doesn't need Patrol's native
/// automator anyway, since GeoClue2 has no OS permission dialog to drive
/// (see test_config.dart's ensurePermissionGranted doc comment).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getLocation() returns the fix from the fake GeoClue2 service',
      (tester) async {
    await tester.pumpWidget(const app.MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('getLocationButton')));

    final deadline = DateTime.now().add(const Duration(seconds: 30));
    String text;
    do {
      if (DateTime.now().isAfter(deadline)) {
        fail('getLocation() did not resolve within 30s');
      }
      await tester.pump(const Duration(milliseconds: 250));
      text =
          tester.widget<Text>(find.byKey(const Key('getLocationText'))).data ??
              '';
    } while (text.contains('unknown'));

    expect(text, isNot(contains('_ERROR')));
    expect(text, isNot(contains('DENIED')));

    // LocationData.toString() renders as 'LocationData<lat: X, long: Y>'.
    final latMatch = RegExp(r'lat:\s*(-?\d+\.?\d*)').firstMatch(text);
    final lngMatch = RegExp(r'long:\s*(-?\d+\.?\d*)').firstMatch(text);
    expect(latMatch, isNotNull, reason: 'Could not parse latitude from: $text');
    expect(
      lngMatch,
      isNotNull,
      reason: 'Could not parse longitude from: $text',
    );

    final lat = double.parse(latMatch!.group(1)!);
    final lng = double.parse(lngMatch!.group(1)!);
    expect(lat, closeTo(testLatitude, coordinateTolerance));
    expect(lng, closeTo(testLongitude, coordinateTolerance));
  });
}
