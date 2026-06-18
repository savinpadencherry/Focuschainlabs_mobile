import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime configuration. Values are read from the bundled `.env` first (filled
/// in before a build), falling back to `--dart-define` for CI/advanced use, and
/// finally a default. Anything left blank falls back to the offline mocks, so
/// the app still runs with zero setup.
///
/// **Security:** When [demoDirectIntegrations] is true (default), Gemini,
/// GitHub, and Trello credentials are used directly from the client bundle.
/// This is acceptable for private internal UAT only — never ship to production.
/// Future backend mode should proxy these calls via Supabase Edge Functions or
/// your own API so secrets never ship in the APK/web bundle.
abstract final class AppConfig {
  static String _read(String key, String fromDefine, {String fallback = ''}) {
    final String env = (dotenv.isInitialized ? dotenv.env[key] : null)?.trim() ?? '';
    if (env.isNotEmpty) return env;
    if (fromDefine.isNotEmpty) return fromDefine;
    return fallback;
  }

  // --- AI: Gemini ---
  static String get geminiApiKey =>
      _read('GEMINI_API_KEY', const String.fromEnvironment('GEMINI_API_KEY'));
  static String get geminiModel => _read(
        'GEMINI_MODEL',
        const String.fromEnvironment('GEMINI_MODEL'),
        fallback: 'gemini-2.5-flash',
      );

  // --- CRM stored in the Leads Agent GitHub repo ---
  static String get githubToken =>
      _read('GITHUB_TOKEN', const String.fromEnvironment('GITHUB_TOKEN'));
  static String get githubCrmRepo => _read(
        'GITHUB_CRM_REPO',
        const String.fromEnvironment('GITHUB_CRM_REPO'),
        fallback: 'savinpadencherry/Focuschainlabs_Leads_Agent',
      );
  static String get githubCrmPath => _read(
        'GITHUB_CRM_PATH',
        const String.fromEnvironment('GITHUB_CRM_PATH'),
        fallback: 'data/crm/contacts.json',
      );
  static String get githubCrmBranch => _read(
        'GITHUB_CRM_BRANCH',
        const String.fromEnvironment('GITHUB_CRM_BRANCH'),
        fallback: 'main',
      );

  /// Streamlit CRM URL opened in the in-app desktop webview.
  static String get crmWebUrl =>
      _read('CRM_WEB_URL', const String.fromEnvironment('CRM_WEB_URL'));

  // --- Trello ---
  static String get trelloKey =>
      _read('TRELLO_KEY', const String.fromEnvironment('TRELLO_KEY'));
  static String get trelloToken =>
      _read('TRELLO_TOKEN', const String.fromEnvironment('TRELLO_TOKEN'));
  static String get trelloListId =>
      _read('TRELLO_LIST_ID', const String.fromEnvironment('TRELLO_LIST_ID'));
  static String get trelloBoardUrl =>
      _read('TRELLO_BOARD_URL', const String.fromEnvironment('TRELLO_BOARD_URL'));

  /// True when the app talks directly to Gemini/GitHub/Trello from the client.
  /// Set `DEMO_DIRECT_INTEGRATIONS=false` (or `--dart-define`) to prepare for
  /// a future backend-proxy mode.
  static bool get demoDirectIntegrations {
    final String raw = _read(
      'DEMO_DIRECT_INTEGRATIONS',
      const String.fromEnvironment('DEMO_DIRECT_INTEGRATIONS'),
      fallback: 'true',
    );
    return raw.toLowerCase() != 'false';
  }

  // --- Capability flags ---
  static bool get hasGemini => demoDirectIntegrations && geminiApiKey.isNotEmpty;
  static bool get hasGithubCrm =>
      demoDirectIntegrations && githubToken.isNotEmpty && githubCrmRepo.isNotEmpty;
  static bool get hasCrmWeb => crmWebUrl.isNotEmpty;
  static bool get hasTrello => demoDirectIntegrations &&
      trelloKey.isNotEmpty &&
      trelloToken.isNotEmpty &&
      trelloListId.isNotEmpty;
  static bool get hasTrelloBoard => trelloBoardUrl.isNotEmpty;
}
