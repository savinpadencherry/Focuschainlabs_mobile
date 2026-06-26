import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../models/crm.dart';
import '../../models/enums.dart';
import '../../models/extraction.dart';
import 'leads_crm_service.dart';

/// CRM backed by the Leads Agent FastAPI REST API (Cloud SQL via Cloud Run).
class RestCrmService implements LeadsCrmService {
  RestCrmService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${AppConfig.cloudRunUrl}$path');

  Map<String, String> get _headers => <String, String>{
        'Authorization': 'Bearer ${AppConfig.apiSecretKey}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<Map<String, dynamic>?> _getContact(String id) async {
    final http.Response res = await _client
        .get(_uri('/api/contacts/$id'), headers: _headers)
        .timeout(const Duration(seconds: 25));
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw http.ClientException('CRM read ${res.statusCode}: ${res.body}');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Map<String, dynamic>? _findByRef(List<Map<String, dynamic>> contacts, String ref) {
    final String r = ref.trim().toLowerCase();
    for (final Map<String, dynamic> c in contacts) {
      if (c['id']?.toString().toLowerCase() == r) return c;
      if (c['name']?.toString().toLowerCase() == r) return c;
    }
    return null;
  }

  List<CrmInteraction> _interactions(Map<String, dynamic> contact) {
    final List<CrmInteraction> out = <CrmInteraction>[];
    for (final String key in <String>['comments', 'interactions', 'email_events', 'emails']) {
      final List<dynamic> list = (contact[key] as List<dynamic>?) ?? <dynamic>[];
      out.addAll(list.whereType<Map<String, dynamic>>().map(CrmInteraction.fromJson));
    }
    out.sort((CrmInteraction a, CrmInteraction b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  @override
  Future<List<CrmContact>> listLeads() async {
    try {
      final http.Response res = await _client
          .get(_uri('/api/contacts'), headers: _headers)
          .timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) return <CrmContact>[];
      final List<dynamic> rows = jsonDecode(res.body) as List<dynamic>;
      return rows
          .whereType<Map<String, dynamic>>()
          .map(CrmContact.fromJson)
          .toList();
    } catch (_) {
      return <CrmContact>[];
    }
  }

  @override
  Future<bool> updateStatus(String contactId, String newStatus) async {
    try {
      final String now = DateTime.now().toUtc().toIso8601String();
      final Map<String, dynamic> patch = <String, dynamic>{
        'status': newStatus,
        'updated_at': now,
      };
      if (newStatus == 'won' || newStatus == 'lost') {
        patch['deal_status'] = newStatus;
      }
      final http.Response res = await _client
          .put(
            _uri('/api/contacts/$contactId'),
            headers: _headers,
            body: jsonEncode(patch),
          )
          .timeout(const Duration(seconds: 25));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<CrmInteraction>> history(String contactRef) async {
    try {
      final http.Response listRes = await _client
          .get(_uri('/api/contacts'), headers: _headers)
          .timeout(const Duration(seconds: 25));
      if (listRes.statusCode != 200) return <CrmInteraction>[];
      final List<dynamic> rows = jsonDecode(listRes.body) as List<dynamic>;
      final List<Map<String, dynamic>> contacts =
          rows.whereType<Map<String, dynamic>>().toList();
      final Map<String, dynamic>? match = _findByRef(contacts, contactRef);
      if (match == null) return <CrmInteraction>[];
      final Map<String, dynamic>? full =
          await _getContact(match['id']?.toString() ?? contactRef);
      if (full == null) return <CrmInteraction>[];
      return _interactions(full);
    } catch (_) {
      return <CrmInteraction>[];
    }
  }

  @override
  Future<CrmWriteResult> upsertLead(
    Extraction extraction, {
    String? transcript,
  }) async {
    try {
      final String now = DateTime.now().toUtc().toIso8601String();
      final String? followUp =
          extraction.followUpDate?.toIso8601String().split('T').first;

      final http.Response listRes = await _client
          .get(_uri('/api/contacts'), headers: _headers)
          .timeout(const Duration(seconds: 25));
      if (listRes.statusCode != 200) {
        return CrmWriteResult.failure('CRM list failed (${listRes.statusCode})');
      }
      final List<dynamic> rows = jsonDecode(listRes.body) as List<dynamic>;
      final List<Map<String, dynamic>> contacts =
          rows.whereType<Map<String, dynamic>>().toList();
      final Map<String, dynamic>? existing = _findByRef(contacts, extraction.client);

      String id;
      String action;
      late Map<String, dynamic> contact;

      if (existing != null) {
        id = existing['id']?.toString() ?? '';
        action = 'merged';
        contact = Map<String, dynamic>.from(
          await _getContact(id) ?? existing,
        );
        if (extraction.dealStageChange != null) {
          contact['status'] = extraction.dealStageChange;
        }
        contact['sentiment'] = extraction.sentiment.wire;
        if (followUp != null) contact['next_follow_up'] = followUp;
      } else {
        action = 'created';
        id = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
        contact = <String, dynamic>{
          'id': id,
          'name': extraction.client,
          'company': extraction.client,
          'status': extraction.dealStageChange ?? 'new',
          'deal_status': 'open',
          'source': 'mobile',
          'sentiment': extraction.sentiment.wire,
          if (followUp != null) 'next_follow_up': followUp,
          'tags': <String>['mobile'],
          'comments': <dynamic>[],
          'created_at': now,
        };
      }

      contact['updated_at'] = now;
      final List<dynamic> comments =
          contact.putIfAbsent('comments', () => <dynamic>[]) as List<dynamic>;
      comments.add(<String, dynamic>{
        'id': DateTime.now().microsecondsSinceEpoch.toRadixString(16),
        'created_at': now,
        'author': 'Mr. Rex (mobile)',
        'body': (transcript == null || transcript.isEmpty)
            ? extraction.summary
            : '${extraction.summary}\n\n“$transcript”',
        'meeting_link': '',
      });

      final http.Response res = await _client
          .post(
            _uri('/api/contacts'),
            headers: _headers,
            body: jsonEncode(contact),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) {
        return CrmWriteResult.failure('CRM write failed (${res.statusCode}): ${res.body}');
      }

      return CrmWriteResult(
        ok: true,
        contactId: id,
        contactName: extraction.client,
        action: action,
        webUrl: AppConfig.hasCrmWeb ? AppConfig.crmWebUrl : null,
      );
    } catch (e) {
      return CrmWriteResult.failure(e.toString());
    }
  }
}
