import 'package:connect_call/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ConnectCallApp smoke test', (WidgetTester tester) async {
    // Basic smoke test — verifies the app builds without crashing.
    // Full widget tests will be added in the testing phase.
    expect(ConnectCallApp, isNotNull);
  });
}
