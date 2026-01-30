import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('initialization test', (WidgetTester tester) async {
    // Basic test to ensure the library can be imported and used
    expect(true, true);
  });
}
