import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import 'trello_service.dart';

/// Creates cards on the configured Trello list via the public REST API:
///   POST https://api.trello.com/1/cards?idList=..&key=..&token=..
class HttpTrelloService implements TrelloService {
  HttpTrelloService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<TrelloResult> createCard({
    required String title,
    String? description,
    DateTime? due,
  }) async {
    try {
      final Uri uri = Uri.parse('https://api.trello.com/1/cards').replace(
        queryParameters: <String, String>{
          'idList': AppConfig.trelloListId,
          'key': AppConfig.trelloKey,
          'token': AppConfig.trelloToken,
          'name': title,
          if (description != null && description.isNotEmpty) 'desc': description,
          if (due != null) 'due': due.toUtc().toIso8601String(),
        },
      );

      final http.Response res =
          await _client.post(uri).timeout(const Duration(seconds: 20));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return TrelloResult.failure('Trello error ${res.statusCode}');
      }
      final Map<String, dynamic> json =
          jsonDecode(res.body) as Map<String, dynamic>;
      return TrelloResult(
        ok: true,
        cardUrl: (json['shortUrl'] ?? json['url'])?.toString(),
      );
    } catch (e) {
      return TrelloResult.failure(e.toString());
    }
  }
}
