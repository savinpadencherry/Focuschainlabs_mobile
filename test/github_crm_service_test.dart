import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:focuschainlabs_mobile/core/models/crm.dart';
import 'package:focuschainlabs_mobile/core/models/enums.dart';
import 'package:focuschainlabs_mobile/core/models/extraction.dart';
import 'package:focuschainlabs_mobile/core/services/crm/crm_exceptions.dart';
import 'package:focuschainlabs_mobile/core/services/crm/github_crm_service.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: '''
GEMINI_API_KEY=
GITHUB_TOKEN=test-token
GITHUB_CRM_REPO=owner/repo
GITHUB_CRM_PATH=data/crm/contacts.json
GITHUB_CRM_BRANCH=main
''');
  });

  Map<String, dynamic> sampleDoc() => <String, dynamic>{
        'version': 1,
        'contacts': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'lead-1',
            'name': 'Acme Corp',
            'company': 'Acme Corp',
            'status': 'new',
            'deal_status': 'open',
            'comments': <dynamic>[],
          },
        ],
      };

  http.Response contentsResponse(Map<String, dynamic> doc, {String sha = 'sha1'}) {
    return http.Response(
      jsonEncode(<String, dynamic>{
        'sha': sha,
        'content': base64.encode(utf8.encode(jsonEncode(doc))),
      }),
      200,
    );
  }

  test('read success returns contacts', () async {
    final GithubCrmService service = GithubCrmService(
      client: MockClient((http.Request request) async {
        expect(request.method, 'GET');
        return contentsResponse(sampleDoc());
      }),
    );
    final leads = await service.listLeads();
    expect(leads, hasLength(1));
    expect(leads.first.name, 'Acme Corp');
  });

  test('create lead appends comment and writes', () async {
    int puts = 0;
    final GithubCrmService service = GithubCrmService(
      client: MockClient((http.Request request) async {
        if (request.method == 'GET') {
          return contentsResponse(<String, dynamic>{'version': 1, 'contacts': <dynamic>[]});
        }
        puts++;
        expect(request.method, 'PUT');
        final Map<String, dynamic> body =
            jsonDecode(request.body) as Map<String, dynamic>;
        final String decoded =
            utf8.decode(base64.decode(body['content'] as String));
        final Map<String, dynamic> doc = jsonDecode(decoded) as Map<String, dynamic>;
        expect((doc['contacts'] as List<dynamic>), hasLength(1));
        return http.Response('{}', 200);
      }),
    );

    final CrmWriteResult result = await service.upsertLead(
      const Extraction(
        client: 'Northstar',
        updateType: UpdateType.comment,
        summary: 'Warm lead',
        sentiment: Sentiment.positive,
      ),
      transcript: 'Called Northstar',
      captureId: 'cap-123',
    );
    expect(result.ok, isTrue);
    expect(puts, 1);
  });

  test('update lead merges into existing contact', () async {
    final GithubCrmService service = GithubCrmService(
      client: MockClient((http.Request request) async {
        if (request.method == 'GET') {
          return contentsResponse(sampleDoc());
        }
        final Map<String, dynamic> body =
            jsonDecode(request.body) as Map<String, dynamic>;
        final String decoded =
            utf8.decode(base64.decode(body['content'] as String));
        final Map<String, dynamic> doc = jsonDecode(decoded) as Map<String, dynamic>;
        final List<dynamic> comments =
            (doc['contacts'] as List<dynamic>).first['comments'] as List<dynamic>;
        expect(comments, hasLength(1));
        return http.Response('{}', 200);
      }),
    );

    final CrmWriteResult result = await service.upsertLead(
      const Extraction(
        client: 'Acme Corp',
        updateType: UpdateType.interaction,
        summary: 'Follow-up call',
        sentiment: Sentiment.neutral,
      ),
      captureId: 'cap-456',
    );
    expect(result.ok, isTrue);
    expect(result.action, 'merged');
  });

  test('401 surfaces typed failure', () async {
    final GithubCrmService service = GithubCrmService(
      client: MockClient((http.Request request) async => http.Response('nope', 401)),
    );
    expect(
      () => service.listLeads(),
      throwsA(isA<CrmServiceException>().having((CrmServiceException e) => e.code, 'code', CrmErrorCode.unauthorized)),
    );
  });

  test('404 surfaces typed failure on read', () async {
    final GithubCrmService service = GithubCrmService(
      client: MockClient((http.Request request) async => http.Response('missing', 404)),
    );
    await expectLater(
      service.listLeads(),
      throwsA(isA<CrmServiceException>().having((CrmServiceException e) => e.code, 'code', CrmErrorCode.notFound)),
    );
  });

  test('409 retries then succeeds', () async {
    int puts = 0;
    final GithubCrmService service = GithubCrmService(
      client: MockClient((http.Request request) async {
        if (request.method == 'GET') {
          return contentsResponse(sampleDoc(), sha: 'sha-$puts');
        }
        puts++;
        if (puts == 1) return http.Response('conflict', 409);
        return http.Response('{}', 200);
      }),
    );

    final CrmWriteResult result = await service.upsertLead(
      const Extraction(
        client: 'Acme Corp',
        updateType: UpdateType.comment,
        summary: 'Retry test',
        sentiment: Sentiment.neutral,
      ),
      captureId: 'cap-789',
    );
    expect(result.ok, isTrue);
    expect(puts, greaterThan(1));
  });

  test('malformed JSON throws CrmServiceException', () async {
    final GithubCrmService service = GithubCrmService(
      client: MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'sha': 'x',
            'content': base64.encode(utf8.encode('not-json')),
          }),
          200,
        );
      }),
    );
    expect(
      () => service.listLeads(),
      throwsA(isA<CrmServiceException>().having((CrmServiceException e) => e.code, 'code', CrmErrorCode.malformed)),
    );
  });

  test('idempotency prevents duplicate comments', () async {
    final Map<String, dynamic> doc = sampleDoc();
    (doc['contacts'] as List<dynamic>).first['comments'] = <dynamic>[
      <String, dynamic>{'id': 'cap-dup', 'body': 'existing'},
    ];
    int puts = 0;
    final GithubCrmService service = GithubCrmService(
      client: MockClient((http.Request request) async {
        if (request.method == 'GET') return contentsResponse(doc);
        puts++;
        return http.Response('{}', 200);
      }),
    );

    final CrmWriteResult result = await service.upsertLead(
      const Extraction(
        client: 'Acme Corp',
        updateType: UpdateType.comment,
        summary: 'Dup',
        sentiment: Sentiment.neutral,
      ),
      captureId: 'cap-dup',
    );
    expect(result.ok, isTrue);
    expect(puts, 1);
  });
}
