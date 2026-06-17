import 'package:flutter_test/flutter_test.dart';
import 'package:focuschainlabs_mobile/main.dart';

void main() {
  testWidgets('renders Mr Rex dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const MrRexApp());
    await tester.pumpAndSettle();

    expect(find.text('Ready to sell smarter?'), findsOneWidget);
    expect(find.text('Ask Rex anything'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
