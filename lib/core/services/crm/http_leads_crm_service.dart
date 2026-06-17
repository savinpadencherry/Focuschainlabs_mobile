import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../models/crm.dart';
import '../../models/enums.dart';
import '../../models/extraction.dart';
import 'leads_crm_service.dart';

/// Talks to the Leads Agent FastAPI (`mobile_api`) on Render. Endpoints:
///   POST {base}/api/leads                      → upsert lead + append comment
///   GET  {base}/api/contacts/{id}/interactions → interaction history
/// Authenticated with the shared `X-API-Key` header.
class HttpLeadsCrmService implements LeadsCrmService {
  HttpLeadsCrmService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> get _headers => <String, String>{
        'Content-Type': 'application/json',
        'X-API-Key': AppConfig.crmApiToken,
      };

  @override
  Future<CrmWriteResult> upsertLead(
    Extraction extraction, {
    String? transcript,
  }) async {
    try {
      final Uri uri = Uri.parse('${AppConfig.crmApiBaseUrl}/api/leads');
      final Map<String, dynamic> payload = <String, dynamic>{
        'name': extraction.client,
        'company': extraction.client,
        'source': 'mobile',
        'status': extraction.dealStageChange,
        'next_follow_up': extraction.followUpDate?.toIso8601String().split('T').first,
        'notes': extraction.notes,
        'sentiment': extraction.sentiment.wire,
        'tags': <String>['mobile'],
        'comment': <String, dynamic>{
          'author': 'Mr. Rex (mobile)',
          'body': transcript == null || transcript.isEmpty
              ? extraction.summary
              : '${extraction.summary}\n\n“$transcript”',
        },
      };

      final http.Response res = await _client
          .post(uri, headers: _headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 25));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        return CrmWriteResult.failure('CRM error ${res.statusCode}');
      }
      final Map<String, dynamic> json =
          jsonDecode(res.body) as Map<String, dynamic>;
      return CrmWriteResult(
        ok: true,
        contactId: json['id']?.toString() ?? '',
        contactName: json['name']?.toString() ?? extraction.client,
        action: json['action']?.toString() ?? 'created',
        webUrl: json['web_url']?.toString(),
      );
    } catch (e) {
      return CrmWriteResult.failure(e.toString());
    }
  }

  @override
  Future<List<CrmInteraction>> history(String contactRef) async {
    try {
      final Uri uri = Uri.parse(
        '${AppConfig.crmApiBaseUrl}/api/contacts/$contactRef/interactions',
      );
      final http.Response res =
          await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return <CrmInteraction>[];
      final List<dynamic> list = jsonDecode(res.body) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(CrmInteraction.fromJson)
          .toList();
    } catch (_) {
      return <CrmInteraction>[];
    }
  }
}
