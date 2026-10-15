import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_assist/features/purchased_items/views/widgets/purchase_summary_card.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required ValueChanged<bool?> onToggleAll,
    required VoidCallback onInvertAll,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settingsProvider = SettingsProvider(prefs);
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settingsProvider,
        child: MaterialApp(
          home: Material(
            child: PurchaseSummaryCard(
              purchaseId: 1,
              itemCount: 1,
              totalItems: 3,
              isChecklistMode: true,
              total: 10.0,
              allChecked: null,
              onToggleAll: onToggleAll,
              onInvertAll: onInvertAll,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('tapping the checkbox triggers onToggleAll only', (tester) async {
    bool? toggledWith;
    var inverted = false;
    await pumpCard(
      tester,
      onToggleAll: (value) => toggledWith = value,
      onInvertAll: () => inverted = true,
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(toggledWith, isNotNull);
    expect(inverted, isFalse);
  });

  testWidgets('long-pressing the checkbox triggers onInvertAll only', (tester) async {
    bool? toggledWith;
    var inverted = false;
    await pumpCard(
      tester,
      onToggleAll: (value) => toggledWith = value,
      onInvertAll: () => inverted = true,
    );

    await tester.longPress(find.byType(Checkbox));
    await tester.pump();

    expect(inverted, isTrue);
    expect(toggledWith, isNull);
  });
}
