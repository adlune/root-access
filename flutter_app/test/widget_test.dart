import 'package:flutter_test/flutter_test.dart';

import 'package:root_access/main.dart';

void main() {
  testWidgets('boot screen shows title and menu', (tester) async {
    await tester.pumpWidget(const RootAccessApp());

    expect(find.text('ROOT_ACCESS'), findsOneWidget);
    expect(find.text('> start session'), findsOneWidget);
    expect(find.text('> open inbox'), findsOneWidget);
  });

  testWidgets('start session opens the terminal', (tester) async {
    await tester.pumpWidget(const RootAccessApp());

    await tester.tap(find.text('> start session'));
    await tester.pumpAndSettle();

    expect(find.text(r'root@localhost:~$ _'), findsOneWidget);
  });
}
