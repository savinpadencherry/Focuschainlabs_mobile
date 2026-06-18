import 'package:flutter_test/flutter_test.dart';

import 'package:focuschainlabs_mobile/core/models/extraction.dart';
import 'package:focuschainlabs_mobile/core/services/ai/mock_ai_service.dart';

void main() {
  const MockAiService ai = MockAiService();

  test('CRM note routes to crm destination', () async {
    final Extraction extraction = await ai.extract(
      'Called Acme Corp about pricing, deal looks warm.',
    );
    expect(extraction.destination, 'crm');
    expect(extraction.isValid, isTrue);
    expect(extraction.client.toLowerCase(), contains('acme'));
  });

  test('Trello task routes to trello destination', () async {
    final Extraction extraction = await ai.extract(
      'Remind me to send the revised quote to Acme by Friday.',
    );
    expect(extraction.destination, 'trello');
    expect(extraction.isValid, isTrue);
  });

  test('unknown destination falls back to crm', () {
    final Extraction extraction = Extraction.fromJson(<String, dynamic>{
      'client': 'Acme',
      'update_type': 'comment',
      'summary': 'Test',
      'sentiment': 'neutral',
      'destination': 'slack',
    });
    expect(extraction.destination, 'crm');
    expect(extraction.routesToTrello, isFalse);
  });

  test('malformed extraction fails validation', () {
    final Extraction extraction = Extraction.fromJson(<String, dynamic>{
      'client': '',
      'update_type': 'comment',
      'summary': '',
      'sentiment': 'neutral',
      'destination': 'crm',
    });
    expect(extraction.isValid, isFalse);
  });

  test('strict destination enum only allows crm or trello in fromJson', () {
    for (final String dest in <String>['crm', 'trello', 'other', '']) {
      final Extraction e = Extraction.fromJson(<String, dynamic>{
        'client': 'X',
        'update_type': 'comment',
        'summary': 'Y',
        'sentiment': 'neutral',
        'destination': dest,
      });
      expect(e.destination, anyOf('crm', 'trello'));
    }
  });
}
