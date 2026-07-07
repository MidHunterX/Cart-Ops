import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_assist/core/widgets/delete_confirmation_dialog.dart';

void main() {
  testWidgets('DeleteConfirmationDialog shows and triggers callbacks correctly', (
    WidgetTester tester,
  ) async {
    bool deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  DeleteConfirmationDialog.show(
                    context,
                    title: 'Delete Group',
                    message: 'Are you sure you want to delete this?',
                    onDelete: () => deleted = true,
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      ),
    );

    // Open dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Group'), findsOneWidget);
    expect(find.text('Are you sure you want to delete this?'), findsOneWidget);

    // Test Cancel Action
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(deleted, isFalse); // Assert it wasn't deleted
    expect(find.byType(AlertDialog), findsNothing);

    // Open dialog again
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Test Confirm Action
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue); // Assert callback fired
  });
}
