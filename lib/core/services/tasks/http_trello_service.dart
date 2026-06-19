import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import 'trello_service.dart';

/// Trello REST client. Auth via the configured key/token; the board is derived
/// once from the configured list, so cards can be searched, moved, updated,
/// completed or deleted across the whole board.
class HttpTrelloService implements TrelloService {
  HttpTrelloService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _boardId;

  Map<String, String> get _auth => <String, String>{
        'key': AppConfig.trelloKey,
        'token': AppConfig.trelloToken,
      };

  Uri _uri(String path, [Map<String, String>? params]) => Uri.https(
        'api.trello.com',
        '/1$path',
        <String, String>{..._auth, ...?params},
      );

  Future<String?> _board() async {
    if (_boardId != null) return _boardId;
    try {
      final http.Response res = await _client
          .get(_uri('/lists/${AppConfig.trelloListId}', <String, String>{'fields': 'idBoard'}))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      _boardId = (jsonDecode(res.body) as Map<String, dynamic>)['idBoard'] as String?;
      return _boardId;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TrelloResult> createCard({
    required String title,
    String? description,
    DateTime? due,
  }) async {
    try {
      final http.Response res = await _client
          .post(_uri('/cards', <String, String>{
            'idList': AppConfig.trelloListId,
            'name': title,
            if (description != null && description.isNotEmpty) 'desc': description,
            if (due != null) 'due': due.toUtc().toIso8601String(),
          }))
          .timeout(const Duration(seconds: 20));
      return _result(res, 'created');
    } catch (e) {
      return TrelloResult.failure(e.toString());
    }
  }

  @override
  Future<List<TrelloCardRef>> findCards(String query) async {
    final String? board = await _board();
    if (board == null) return <TrelloCardRef>[];
    try {
      final http.Response res = await _client
          .get(_uri('/boards/$board/cards', <String, String>{
            'fields': 'name,idList,shortUrl',
            'filter': 'open',
          }))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return <TrelloCardRef>[];
      final String q = query.trim().toLowerCase();
      return (jsonDecode(res.body) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .where((Map<String, dynamic> c) =>
              (c['name'] as String? ?? '').toLowerCase().contains(q))
          .map((Map<String, dynamic> c) => TrelloCardRef(
                id: c['id'].toString(),
                name: c['name'].toString(),
                listId: c['idList'].toString(),
                url: c['shortUrl']?.toString(),
              ))
          .toList();
    } catch (_) {
      return <TrelloCardRef>[];
    }
  }

  @override
  Future<List<TrelloListRef>> lists() async {
    final String? board = await _board();
    if (board == null) return <TrelloListRef>[];
    try {
      final http.Response res = await _client
          .get(_uri('/boards/$board/lists', <String, String>{'fields': 'name'}))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return <TrelloListRef>[];
      return (jsonDecode(res.body) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> l) =>
              TrelloListRef(id: l['id'].toString(), name: l['name'].toString()))
          .toList();
    } catch (_) {
      return <TrelloListRef>[];
    }
  }

  @override
  Future<TrelloResult> moveCard(String cardId, String listId) =>
      _put(cardId, <String, String>{'idList': listId}, 'moved');

  @override
  Future<TrelloResult> updateCard(
    String cardId, {
    String? name,
    String? description,
    DateTime? due,
  }) =>
      _put(cardId, <String, String>{
        if (name != null) 'name': name,
        if (description != null) 'desc': description,
        if (due != null) 'due': due.toUtc().toIso8601String(),
      }, 'updated');

  @override
  Future<TrelloResult> completeCard(String cardId) =>
      _put(cardId, <String, String>{'dueComplete': 'true'}, 'completed');

  @override
  Future<TrelloResult> deleteCard(String cardId) async {
    try {
      final http.Response res =
          await _client.delete(_uri('/cards/$cardId')).timeout(const Duration(seconds: 20));
      return res.statusCode >= 200 && res.statusCode < 300
          ? const TrelloResult(ok: true, action: 'deleted')
          : TrelloResult.failure('Trello ${res.statusCode}');
    } catch (e) {
      return TrelloResult.failure(e.toString());
    }
  }

  Future<TrelloResult> _put(String cardId, Map<String, String> params, String action) async {
    try {
      final http.Response res =
          await _client.put(_uri('/cards/$cardId', params)).timeout(const Duration(seconds: 20));
      return _result(res, action);
    } catch (e) {
      return TrelloResult.failure(e.toString());
    }
  }

  TrelloResult _result(http.Response res, String action) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      return TrelloResult.failure('Trello ${res.statusCode}');
    }
    final Map<String, dynamic> json = jsonDecode(res.body) as Map<String, dynamic>;
    return TrelloResult(
      ok: true,
      action: action,
      cardUrl: (json['shortUrl'] ?? json['url'])?.toString(),
    );
  }
}
