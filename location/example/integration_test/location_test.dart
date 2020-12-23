import 'package:location/location.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Can instantiate Location object', (WidgetTester tester) async {
    final Location location = Location();
    expect(location, isNotNull);
  });
}
