import 'package:flutter_test/flutter_test.dart';

import 'package:focuschainlabs_mobile/core/utils/inr.dart';

void main() {
  group('reading a budget the way a rep writes it', () {
    test('crore, in every spelling that reaches the box', () {
      for (final String written in <String>['1.2 Cr', '1.2cr', '1.2 crore', '1.2C']) {
        expect(Inr.parse(written), 12000000, reason: written);
      }
    });

    test('lakh, likewise', () {
      for (final String written in <String>['80 L', '80l', '80 lakh', '80 lac']) {
        expect(Inr.parse(written), 8000000, reason: written);
      }
    });

    test('a bare number is rupees, not lakhs', () {
      // Someone typing 4500000 means forty-five lakh. Guessing a unit here
      // would silently multiply their budget by a hundred thousand.
      expect(Inr.parse('4500000'), 4500000);
      expect(Inr.parse('45,00,000'), 4500000);
    });

    test('nothing in the box is not a filter', () {
      expect(Inr.parse(''), 0);
      expect(Inr.parse('   '), 0);
      expect(Inr.parse('crore'), 0);
    });
  });

  group('printing one back', () {
    test('a trailing zero is precision that is not there', () {
      expect(Inr.format(12000000), '₹1.2 Cr');
      expect(Inr.format(30000000), '₹3 Cr');
      expect(Inr.format(8000000), '₹80 L');
    });

    test('nothing prints for no budget', () {
      expect(Inr.format(0), '');
    });

    test('what is typed survives the round trip', () {
      for (final String written in <String>['1.2 Cr', '80 L', '3 Cr']) {
        expect(Inr.format(Inr.parse(written)), '₹$written');
      }
    });
  });
}
