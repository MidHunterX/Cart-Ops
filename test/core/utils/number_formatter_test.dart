import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_assist/core/utils/number_formatter.dart';

void main() {
  group('NumberFormatting Extension', () {
    test('toWholeNumberString formats correctly', () {
      expect(5.0.toWholeNumberString(), '5');
      expect(5.5.toWholeNumberString(), '5.50');
      expect(0.0.toWholeNumberString(), '0');
    });

    test('toWeightString formats correctly', () {
      expect(2.0.toWeightString('kg'), '2kg');
      expect(1.25.toWeightString('kg'), '1.25kg');
    });

    test('toCurrencyString formats correctly', () {
      expect(10.0.toCurrencyString('\$'), '\$10');
      expect(10.99.toCurrencyString('₹'), '₹10.99');
    });
  });
}
