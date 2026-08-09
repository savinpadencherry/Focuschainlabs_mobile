import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime configuration.
///
/// Values come from the bundled `.env` first (written by CI before a build),
/// then `--dart-define`, then a default. The release workflow writes `.env`, so
/// a build with no secrets configured still compiles and runs — it just cannot
/// reach the CRM, and says so rather than pretending with mock data.
abstract final class AppConfig {
  static String _read(String key, String fromDefine, {String fallback = ''}) {
    final String env = (dotenv.isInitialized ? dotenv.env[key] : null)?.trim() ?? '';
    if (env.isNotEmpty) return env;
    if (fromDefine.isNotEmpty) return fromDefine;
    return fallback;
  }

  // --- Secona mobile API (Cloud Run, same database as the web app) ---

  /// The deployed mobile API.
  ///
  /// Committed rather than injected, and that is deliberate: it is a public
  /// address, not a credential. Every request is authorized by the signed-in
  /// user's Google ID token, so the tenant and role come from who is holding
  /// the phone. A shared secret baked into an APK would be worse than useless
  /// — anyone can unzip an APK — which is why there isn't one.
  ///
  /// Having a default also removes a whole failure mode: a build made without
  /// the config set produces an app that installs, signs in, and then cannot
  /// reach anything, with no clue on screen as to why.
  static const String defaultApiBaseUrl =
      'https://mobile-api-107807038199.asia-south1.run.app';

  /// Base URL of the mobile API. `.env` or `--dart-define` override the
  /// default, which is what a staging build would do.
  static String get apiBaseUrl {
    final String raw = _read(
      'API_BASE_URL',
      const String.fromEnvironment('API_BASE_URL'),
      fallback: defaultApiBaseUrl,
    );
    // A trailing slash would produce `//api/pipeline`, which Cloud Run 404s.
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  /// The Streamlit CRM, opened in an in-app webview for the desktop-only
  /// surfaces the phone deliberately does not reimplement (finance, proposals,
  /// document upload). Public address, same reasoning as [defaultApiBaseUrl].
  static String get crmWebUrl => _read(
        'CRM_WEB_URL',
        const String.fromEnvironment('CRM_WEB_URL'),
        fallback: 'https://crm-app-rgyrtjmm3q-el.a.run.app',
      );

  // --- Capability flags ---

  static bool get hasApi => apiBaseUrl.isNotEmpty;
  static bool get hasCrmWeb => crmWebUrl.isNotEmpty;
}
