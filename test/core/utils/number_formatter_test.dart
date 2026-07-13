import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_assist/core/utils/number_formatter.dart';

void main() {
  group('NumberFormatting Extension', () {
    group('toWholeNumberString', () {
      test('formats whole numbers correctly', () {
        expect(0.0.toWholeNumberString(), '0');
        expect(1.0.toWholeNumberString(), '1');
        expect(5.0.toWholeNumberString(), '5');
        expect(10.0.toWholeNumberString(), '10');
        expect(100.0.toWholeNumberString(), '100');
      });

      test('formats decimal numbers with two decimal places', () {
        expect(1.5.toWholeNumberString(), '1.50');
        expect(5.5.toWholeNumberString(), '5.50');
        expect(3.14.toWholeNumberString(), '3.14');
        expect(0.5.toWholeNumberString(), '0.50');
        expect(99.99.toWholeNumberString(), '99.99');
      });

      test('formats numbers with many decimal places correctly', () {
        expect(1.2345.toWholeNumberString(), '1.23');
        expect(5.6789.toWholeNumberString(), '5.68');
        expect(0.1234.toWholeNumberString(), '0.12');
        expect(123.456.toWholeNumberString(), '123.46');
      });

      test('handles negative numbers correctly', () {
        expect((-1.0).toWholeNumberString(), '-1');
        expect((-5.5).toWholeNumberString(), '-5.50');
        expect((-3.14159).toWholeNumberString(), '-3.14');
        expect((-0.5).toWholeNumberString(), '-0.50');
        expect((-0.0).toWholeNumberString(), '0');
      });

      test('handles large numbers correctly', () {
        expect(1000000.0.toWholeNumberString(), '1000000');
        expect(1234567.89.toWholeNumberString(), '1234567.89');
        expect(999999.999.toWholeNumberString(), '1000000.00');
      });

      test('handles very small numbers correctly', () {
        expect(0.001.toWholeNumberString(), '0.00');
        expect(0.009.toWholeNumberString(), '0.01');
        expect(0.0001.toWholeNumberString(), '0.00');
      });
    });

    group('toPriceString', () {
      test('formats whole numbers as integers', () {
        expect(0.0.toPriceString(), '0');
        expect(1.0.toPriceString(), '1');
        expect(5.0.toPriceString(), '5');
        expect(10.0.toPriceString(), '10');
        expect(100.0.toPriceString(), '100');
      });

      test('formats decimal numbers with two decimal places', () {
        expect(1.23.toPriceString(), '1.23');
        expect(5.50.toPriceString(), '5.50');
        expect(0.99.toPriceString(), '0.99');
        expect(99.99.toPriceString(), '99.99');
        expect(0.01.toPriceString(), '0.01');
      });

      test('formats numbers with more than two decimal places correctly', () {
        expect(1.2345.toPriceString(), '1.23');
        expect(5.6789.toPriceString(), '5.68');
        expect(0.1234.toPriceString(), '0.12');
        expect(123.456.toPriceString(), '123.46');
        expect(1.999.toPriceString(), '2.00');
      });

      test('handles negative numbers correctly', () {
        expect((-1.0).toPriceString(), '-1');
        expect((-5.50).toPriceString(), '-5.50');
        expect((-3.14159).toPriceString(), '-3.14');
        expect((-0.99).toPriceString(), '-0.99');
        expect((-0.01).toPriceString(), '-0.01');
        expect((-0.0).toPriceString(), '0');
      });

      test('handles numbers near zero correctly', () {
        expect(0.001.toPriceString(), '0.00');
        expect(0.009.toPriceString(), '0.01');
        expect(0.0001.toPriceString(), '0.00');
      });

      test('handles large numbers correctly', () {
        expect(1000000.0.toPriceString(), '1000000');
        expect(1234567.89.toPriceString(), '1234567.89');
        expect(999999.999.toPriceString(), '1000000.00');
      });

      test('handles numbers with trailing zeros correctly', () {
        expect(1.50.toPriceString(), '1.50');
        expect(2.00.toPriceString(), '2');
        expect(0.00.toPriceString(), '0');
        expect(10.10.toPriceString(), '10.10');
      });
    });

    group('toWeightString', () {
      test('formats whole numbers without unit', () {
        expect(0.0.toWeightString(null), '0');
        expect(1.0.toWeightString(null), '1');
        expect(5.0.toWeightString(null), '5');
        expect(10.0.toWeightString(null), '10');
        expect(100.0.toWeightString(null), '100');
      });

      test('formats whole numbers with unit', () {
        expect(0.0.toWeightString('kg'), '0kg');
        expect(1.0.toWeightString('kg'), '1kg');
        expect(5.0.toWeightString('g'), '5g');
        expect(10.0.toWeightString('lbs'), '10lbs');
        expect(100.0.toWeightString('oz'), '100oz');
      });

      test('formats decimal numbers without unit', () {
        expect(1.25.toWeightString(null), '1.25');
        expect(5.50.toWeightString(null), '5.5');
        expect(0.5.toWeightString(null), '0.5');
        expect(99.99.toWeightString(null), '99.99');
        expect(3.14159.toWeightString(null), '3.14159');
      });

      test('formats decimal numbers with unit', () {
        expect(1.25.toWeightString('kg'), '1.25kg');
        expect(5.50.toWeightString('g'), '5.5g');
        expect(0.5.toWeightString('lbs'), '0.5lbs');
        expect(99.99.toWeightString('oz'), '99.99oz');
        expect(3.14159.toWeightString('kg'), '3.14159kg');
      });

      test('formats numbers with trailing zeros correctly', () {
        expect(1.0.toWeightString('kg'), '1kg');
        expect(1.0.toWeightString('g'), '1g');
        expect(0.0.toWeightString('kg'), '0kg');
        expect(1.30.toWeightString('kg'), '1.3kg');
        expect(1.00.toWeightString('kg'), '1kg');
      });

      test('handles negative numbers correctly', () {
        expect((-1.0).toWeightString('kg'), '-1kg');
        expect((-5.50).toWeightString('g'), '-5.5g');
        expect((-0.5).toWeightString('lbs'), '-0.5lbs');
        expect((-3.14159).toWeightString('kg'), '-3.14159kg');
        expect((-0.0).toWeightString('kg'), '0kg');
      });

      test('handles large numbers correctly', () {
        expect(1000000.0.toWeightString('kg'), '1000000kg');
        expect(1234567.89.toWeightString('g'), '1234567.89g');
        expect(999999.999.toWeightString('kg'), '999999.999kg');
      });

      test('handles empty string unit', () {
        expect(1.0.toWeightString(''), '1');
        expect(1.25.toWeightString(''), '1.25');
        expect(0.0.toWeightString(''), '0');
      });

      test('handles unit with spaces', () {
        expect(1.0.toWeightString(' kg'), '1 kg');
        expect(1.25.toWeightString(' kg'), '1.25 kg');
        expect(1.0.toWeightString('g '), '1g ');
        expect(1.0.toWeightString(' kg '), '1 kg ');
      });
    });

    group('toCurrencyString', () {
      test('formats whole numbers with currency symbol', () {
        expect(0.0.toCurrencyString('\$'), '\$0');
        expect(1.0.toCurrencyString('\$'), '\$1');
        expect(5.0.toCurrencyString('€'), '€5');
        expect(10.0.toCurrencyString('₹'), '₹10');
        expect(100.0.toCurrencyString('£'), '£100');
      });

      test('formats decimal numbers with currency symbol', () {
        expect(1.23.toCurrencyString('\$'), '\$1.23');
        expect(5.50.toCurrencyString('€'), '€5.50');
        expect(0.99.toCurrencyString('₹'), '₹0.99');
        expect(99.99.toCurrencyString('£'), '£99.99');
        expect(0.01.toCurrencyString('\$'), '\$0.01');
      });

      test('formats numbers with more than two decimal places correctly', () {
        expect(1.2345.toCurrencyString('\$'), '\$1.23');
        expect(5.6789.toCurrencyString('€'), '€5.68');
        expect(0.1234.toCurrencyString('₹'), '₹0.12');
        expect(123.456.toCurrencyString('£'), '£123.46');
        expect(1.999.toCurrencyString('\$'), '\$2.00');
      });

      test('handles negative numbers correctly', () {
        expect((-1.0).toCurrencyString('\$'), '-\$1');
        expect((-5.50).toCurrencyString('€'), '-€5.50');
        expect((-3.14159).toCurrencyString('₹'), '-₹3.14');
        expect((-0.99).toCurrencyString('£'), '-£0.99');
        expect((-0.01).toCurrencyString('\$'), '-\$0.01');
        expect((-0.0).toCurrencyString('\$'), '\$0');
      });

      test('handles multi-character currency symbols', () {
        expect(1.0.toCurrencyString('USD'), 'USD1');
        expect(1.23.toCurrencyString('EUR'), 'EUR1.23');
        expect(5.50.toCurrencyString('GBP'), 'GBP5.50');
        expect(10.99.toCurrencyString('JPY'), 'JPY10.99');
      });

      test('handles numbers near zero correctly', () {
        expect(0.001.toCurrencyString('\$'), '\$0.00');
        expect(0.009.toCurrencyString('\$'), '\$0.01');
        expect(0.0001.toCurrencyString('\$'), '\$0.00');
      });

      test('handles large numbers correctly', () {
        expect(1000000.0.toCurrencyString('\$'), '\$1000000');
        expect(1234567.89.toCurrencyString('€'), '€1234567.89');
        expect(999999.999.toCurrencyString('₹'), '₹1000000.00');
      });

      test('handles numbers with trailing zeros correctly', () {
        expect(1.50.toCurrencyString('\$'), '\$1.50');
        expect(2.00.toCurrencyString('\$'), '\$2');
        expect(0.00.toCurrencyString('\$'), '\$0');
        expect(10.10.toCurrencyString('\$'), '\$10.10');
      });

      test('handles currency symbols with spaces', () {
        expect(1.0.toCurrencyString('\$ '), '\$ 1');
        expect(1.23.toCurrencyString(' \$'), ' \$1.23');
        expect(5.50.toCurrencyString(' € '), ' € 5.50');
      });

      test('handles empty currency symbol', () {
        expect(1.0.toCurrencyString(''), '1');
        expect(1.23.toCurrencyString(''), '1.23');
        expect(0.0.toCurrencyString(''), '0');
      });
    });

    // Edge cases that apply to all methods
    group('Edge Cases - All Methods', () {
      /* FIX:
        test('handles NaN values gracefully', () {
        final nan = double.nan;
        expect(nan.toWholeNumberString(), startsWith('NaN'));
        expect(nan.toPriceString(), startsWith('NaN'));
        expect(nan.toWeightString('kg'), startsWith('NaNkg'));
        expect(nan.toCurrencyString('\$'), startsWith('\$NaN'));
      });*/

      /* FIX:
        test('handles infinity values gracefully', () {
        final infinity = double.infinity;
        final negInfinity = double.negativeInfinity;
        expect(infinity.toWholeNumberString(), 'Infinity');
        expect(infinity.toPriceString(), 'Infinity');
        expect(infinity.toWeightString('kg'), 'Infinitykg');
        expect(infinity.toCurrencyString('\$'), '\$Infinity');
        expect(negInfinity.toWholeNumberString(), '-Infinity');
        expect(negInfinity.toPriceString(), '-Infinity');
        expect(negInfinity.toWeightString('kg'), '-Infinitykg');
        expect(negInfinity.toCurrencyString('\$'), '-\$Infinity');
      });*/

      test('handles max and min double values', () {
        final max = double.maxFinite;
        final min = double.minPositive;

        // Just verify they don't throw exceptions
        expect(() => max.toWholeNumberString(), returnsNormally);
        expect(() => max.toPriceString(), returnsNormally);
        expect(() => max.toWeightString('kg'), returnsNormally);
        expect(() => max.toCurrencyString('\$'), returnsNormally);

        expect(() => min.toWholeNumberString(), returnsNormally);
        expect(() => min.toPriceString(), returnsNormally);
        expect(() => min.toWeightString('kg'), returnsNormally);
        expect(() => min.toCurrencyString('\$'), returnsNormally);
      });
    });
  });
}
