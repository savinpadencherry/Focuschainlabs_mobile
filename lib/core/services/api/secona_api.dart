import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';

/// A call the API refused or could not answer.
///
/// Carries the server's own `detail` string where there is one. The API writes
/// those for a person to read ("srikant@… is not a member of any organization"),
/// so surfacing it beats replacing it with a generic failure message.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  /// Signed in with Google, but not on the CRM's invite list.
  bool get isNotAMember => statusCode == 403;

  /// The token expired or was rejected — sign in again.
  bool get isUnauthenticated => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// The single HTTP door to the CRM.
///
/// Every request carries a Firebase ID token, which the API verifies and
/// resolves to an organization and role. That is the whole authorization
/// model: the client never sends an org id, because an org id supplied by the
/// caller is a request to read someone else's tenant.
///
/// Tokens are fetched per request rather than cached. `getIdToken()` returns a
/// cached value until it is close to expiry and refreshes transparently, so the
/// cost is a field read and the alternative is a 401 an hour into a session.
class SeconaApi {
  SeconaApi({http.Client? client, FirebaseAuth? auth})
      : _client = client ?? http.Client(),
        _authOverride = auth;

  final http.Client _client;
  final FirebaseAuth? _authOverride;

  /// Resolved lazily. `FirebaseAuth.instance` throws when Firebase has not
  /// been initialised, and constructing this class must not be what surfaces
  /// that — the app registers it at startup, long before anyone signs in.
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  /// How long any single call may take before it is abandoned.
  ///
  /// Generous, because an Ona turn can involve a language-model round trip;
  /// a rep on a site visit would rather wait than retype the question.
  static const Duration _timeout = Duration(seconds: 45);

  String get _baseUrl => AppConfig.apiBaseUrl;

  bool get isConfigured => _baseUrl.isNotEmpty;

  Future<String> _idToken() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw const ApiException(401, 'Signed out. Sign in again to continue.');
    }
    final String? token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(401, 'Could not refresh your session.');
    }
    return token;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final Map<String, String> params = <String, String>{};
    (query ?? const <String, dynamic>{}).forEach((String k, dynamic v) {
      if (v == null) return;
      final String s = v.toString();
      // An empty filter means "no filter"; sending it as `locality=` would make
      // the server match on the empty string.
      if (s.isEmpty || s == '0') return;
      params[k] = s;
    });
    return Uri.parse('$_baseUrl$path').replace(
      queryParameters: params.isEmpty ? null : params,
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    return _send(() async => _client.get(
          _uri(path, query),
          headers: await _headers(),
        ));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _send(() async => _client.post(
          _uri(path),
          headers: await _headers(json: true),
          body: jsonEncode(body ?? const <String, dynamic>{}),
        ));
  }

  /// An absolute URL on this API, for widgets that fetch bytes themselves.
  String urlFor(String path) => '$_baseUrl$path';

  /// Headers for such a fetch. Image.network takes these, so a photo behind
  /// the API's permission check can be rendered without a signed link — and
  /// signing is exactly what does not work here, since Cloud Run's metadata
  /// credentials cannot sign an object URL.
  Future<Map<String, String>> authHeaders() async =>
      <String, String>{'Authorization': 'Bearer ${await _idToken()}'};

  Future<Map<String, String>> _headers({bool json = false}) async {
    return <String, String>{
      'Authorization': 'Bearer ${await _idToken()}',
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    if (!isConfigured) {
      throw const ApiException(
        503,
        'This build has no API address. Reinstall the latest APK.',
      );
    }

    late final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException(
        408,
        'That took too long to answer. Try again — or open the lead and read '
        'the record directly.',
      );
    } catch (error) {
      // Not the raw exception. It reached the screen as "ClientException:
      // Software caused connection abort, uri=https://mobile-api-1078…" — a
      // sentence that tells a rep standing in a flat nothing they can act on,
      // and puts an internal hostname in front of whoever is next to them.
      throw ApiException(0, _unreachable(error));
    }

    final Map<String, dynamic> decoded = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    throw ApiException(
      response.statusCode,
      (decoded['detail'] ?? decoded['message'] ?? 'Request failed.').toString(),
    );
  }

  /// What a dropped request means, in words someone can act on.
  static String _unreachable(Object error) {
    final String raw = error.toString().toLowerCase();
    if (raw.contains('abort') ||
        raw.contains('reset') ||
        raw.contains('closed')) {
      return 'The connection dropped before the answer came back. '
          'Try again in a moment.';
    }
    if (raw.contains('failed host lookup') ||
        raw.contains('no address') ||
        raw.contains('unreachable') ||
        raw.contains('network is')) {
      return 'No connection. Check your signal and try again.';
    }
    return 'Could not reach the CRM. Try again in a moment.';
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    try {
      final dynamic parsed = jsonDecode(response.body);
      // A list response (none today, but /shares could become one) still has to
      // arrive as a map so callers have one shape to handle.
      return parsed is Map<String, dynamic>
          ? parsed
          : <String, dynamic>{'data': parsed};
    } catch (_) {
      // An HTML error page from an infrastructure layer, not the API.
      return <String, dynamic>{'detail': 'Unexpected response from the server.'};
    }
  }

  void dispose() => _client.close();
}
