import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../models/crm.dart';
import '../../models/enums.dart';
import '../../models/extraction.dart';
import 'leads_crm_service.dart';

/// Reads and writes the Leads Agent CRM **directly in its GitHub repo**
/// (`data/crm/contacts.json`) via the Contents API — no separate server. This
/// is the same store the Streamlit CRM uses, so updates appear in both.
///
/// Auth: a PAT (`GITHUB_TOKEN`) with "Contents: read and write".
class GithubCrmService implements LeadsCrmService {
  GithubCrmService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri get _contentsUri => Uri.parse(
        'https://api.github.com/repos/${AppConfig.githubCrmRepo}'
        '/contents/${AppConfig.githubCrmPath}',
      );

  Map<String, String> get _headers => <String, String>{
        'Accept': 'application/vnd.github+json',
        'Authorization': 'Bearer ${AppConfig.githubToken}',
        'X-GitHub-Api-Version': '2022-11-28',
      };

  // --- read -----------------------------------------------------------------

  /// Returns the parsed CRM document and the file SHA (needed to write back).
  Future<(Map<String, dynamic>, String)> _load() async {
    final Uri uri = _contentsUri.replace(
      queryParameters: <String, String>{'ref': AppConfig.githubCrmBranch},
    );
    final http.Response res =
        await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) {
      throw http.ClientException('GitHub CRM read ${res.statusCode}: ${res.body}');
    }
    final Map<String, dynamic> meta = jsonDecode(res.body) as Map<String, dynamic>;
    final String sha = meta['sha'] as String;
    final String encoded = (meta['content'] as String? ?? '').replaceAll('\n', '');
    final String raw = utf8.decode(base64.decode(encoded));
    final Map<String, dynamic> doc = raw.trim().isEmpty
        ? <String, dynamic>{'contacts': <dynamic>[]}
        : jsonDecode(raw) as Map<String, dynamic>;
    doc.putIfAbsent('contacts', () => <dynamic>[]);
    return (doc, sha);
  }

  Future<void> _save(Map<String, dynamic> doc, String sha, String message) async {
    doc['updated_at'] = DateTime.now().toUtc().toIso8601String();
    final String encoded = base64.encode(utf8.encode(jsonEncode(doc)));
    final http.Response res = await _client
        .put(
          _contentsUri,
          headers: _headers,
          body: jsonEncode(<String, dynamic>{
            'message': message,
            'content': encoded,
            'sha': sha,
            'branch': AppConfig.githubCrmBranch,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw http.ClientException('GitHub CRM write ${res.statusCode}: ${res.body}');
    }
  }

  // --- LeadsCrmService ------------------------------------------------------

  @override
  Future<List<CrmContact>> listLeads() async {
    try {
      final (Map<String, dynamic> doc, _) = await _load();
      return _contacts(doc)
          .map((Map<String, dynamic> c) => CrmContact.fromJson(c))
          .toList();
    } catch (_) {
      return <CrmContact>[];
    }
  }

  @override
  Future<List<CrmInteraction>> history(String contactRef) async {
    try {
      final (Map<String, dynamic> doc, _) = await _load();
      final Map<String, dynamic>? contact = _find(doc, contactRef);
      if (contact == null) return <CrmInteraction>[];
      return _interactions(contact);
    } catch (_) {
      return <CrmInteraction>[];
    }
  }

  @override
  Future<bool> updateStatus(String contactId, String newStatus) async {
    try {
      final (Map<String, dynamic> doc, String sha) = await _load();
      final Map<String, dynamic>? contact = _find(doc, contactId);
      if (contact == null) return false;
      contact['status'] = newStatus;
      if (newStatus == 'won' || newStatus == 'lost') {
        contact['deal_status'] = newStatus;
      }
      contact['updated_at'] = DateTime.now().toUtc().toIso8601String();
      await _save(doc, sha, 'mobile: status $contactId → $newStatus');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<CrmWriteResult> upsertLead(
    Extraction extraction, {
    String? transcript,
  }) async {
    try {
      final (Map<String, dynamic> doc, String sha) = await _load();
      final (String action, Map<String, dynamic> contact) =
          _findOrCreate(doc, extraction.client);

      if (extraction.dealStageChange != null) {
        contact['status'] = extraction.dealStageChange;
      }
      if (extraction.followUpDate != null) {
        contact['next_follow_up'] =
            extraction.followUpDate!.toIso8601String().split('T').first;
      }
      contact['sentiment'] = extraction.sentiment.wire;
      contact['updated_at'] = DateTime.now().toUtc().toIso8601String();

      final List<dynamic> comments =
          contact.putIfAbsent('comments', () => <dynamic>[]) as List<dynamic>;
      comments.add(<String, dynamic>{
        'id': DateTime.now().microsecondsSinceEpoch.toRadixString(16),
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'author': 'Mr. Rex (mobile)',
        'body': (transcript == null || transcript.isEmpty)
            ? extraction.summary
            : '${extraction.summary}\n\n“$transcript”',
        'meeting_link': '',
      });

      await _save(doc, sha, 'mobile: $action ${contact['name']}');
      return CrmWriteResult(
        ok: true,
        contactId: contact['id']?.toString() ?? '',
        contactName: contact['name']?.toString() ?? extraction.client,
        action: action,
        webUrl: AppConfig.hasCrmWeb ? AppConfig.crmWebUrl : null,
      );
    } catch (e) {
      return CrmWriteResult.failure(e.toString());
    }
  }

  // --- helpers --------------------------------------------------------------

  List<Map<String, dynamic>> _contacts(Map<String, dynamic> doc) =>
      (doc['contacts'] as List<dynamic>).whereType<Map<String, dynamic>>().toList();

  Map<String, dynamic>? _find(Map<String, dynamic> doc, String ref) {
    final String r = ref.trim().toLowerCase();
    for (final Map<String, dynamic> c in _contacts(doc)) {
      if (c['id']?.toString().toLowerCase() == r) return c;
      if (c['name']?.toString().toLowerCase() == r) return c;
    }
    return null;
  }

  (String, Map<String, dynamic>) _findOrCreate(Map<String, dynamic> doc, String name) {
    final Map<String, dynamic>? existing = _find(doc, name);
    if (existing != null) return ('merged', existing);
    final Map<String, dynamic> contact = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toRadixString(16),
      'name': name,
      'company': name,
      'status': 'new',
      'deal_status': 'open',
      'source': 'mobile',
      'tags': <String>['mobile'],
      'comments': <dynamic>[],
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    (doc['contacts'] as List<dynamic>).add(contact);
    return ('created', contact);
  }

  List<CrmInteraction> _interactions(Map<String, dynamic> contact) {
    final List<CrmInteraction> out = <CrmInteraction>[];
    for (final String key in <String>['comments', 'interactions', 'emails']) {
      final List<dynamic> list = (contact[key] as List<dynamic>?) ?? <dynamic>[];
      out.addAll(list.whereType<Map<String, dynamic>>().map(CrmInteraction.fromJson));
    }
    out.sort((CrmInteraction a, CrmInteraction b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }
}
