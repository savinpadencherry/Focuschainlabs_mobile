import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focuschainlabs_mobile/app/app.dart';
import 'package:focuschainlabs_mobile/core/get.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    initializeGetIt();
  });

  testWidgets('app boots to the branded splash', (WidgetTester tester) async {
    await tester.pumpWidget(const MrRexApp());
    // First frame renders the splash (avoid pumpAndSettle: the splash has an
    // indeterminate progress indicator that never settles).
    await tester.pump();

    expect(find.text('Mr. Rex'), findsOneWidget);
    expect(find.text('Your sales companion'), findsOneWidget);

    // Flush the auth gate's startup timer and settle the transition so no
    // timer is left pending at teardown.
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('auth gate resolves to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MrRexApp());

    // Advance past the splash delay so the auth gate restores the (empty)
    // session and lands on login.
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
