import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_assist/core/widgets/search_filter.dart';

void main() {
  testWidgets('SearchFilter updates and clears text properly', (WidgetTester tester) async {
    final controller = TextEditingController();
    String changedValue = '';
    bool cleared = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchFilter(
            controller: controller,
            hintText: 'Search items',
            onChanged: (val) => changedValue = val,
            onClear: () => cleared = true,
          ),
        ),
      ),
    );

    // Initial state validation
    expect(find.text('Search items'), findsOneWidget);
    expect(find.byIcon(Icons.clear), findsNothing);

    // Simulate entering text
    await tester.enterText(find.byType(SearchBar), 'Apple');
    await tester.pump();

    expect(changedValue, 'Apple');
    expect(find.byIcon(Icons.clear), findsOneWidget); // Clear icon should appear

    // Simulate tapping clear icon
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(controller.text, '');
    expect(cleared, isTrue);
    expect(changedValue, '');
    expect(find.byIcon(Icons.clear), findsNothing); // Clear icon should disappear
  });
}
