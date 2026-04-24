import 'package:flutter_test/flutter_test.dart';

import 'package:tugasets/main.dart';

void main() {
  testWidgets('shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Choir Practice Attendance'), findsOneWidget);
    expect(find.text('Welcome back to your choir practice hub'), findsNothing);
  });
}
