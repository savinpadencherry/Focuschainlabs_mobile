import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime configuration. Values are read from the bundled `.env` first,
/// falling back to `--dart-define`, and finally a default. Anything left blank
/// falls back to offline mocks so the app still starts without integrations.
///
/// Client-visible configuration such as a Supabase publishable key is safe to
/// bundle only when Row Level Security is enabled. Service-role keys must never
/// be shipped in Flutter.
abstract final class AppConfig {
  static String _read(String key, String fromDefine, {String fallback = ''}) {
    final String env =
        (dotenv.isInitialized ? dotenv.env[key] : null)?.trim() ?? '';
    if (env.isNotEmpty) return env;
    if (fromDefine.isNotEmpty) return fromDefine;
    return fallback;
  }

  static String _readAny(
    List<String> keys,
    List<String> defines, {
    String fallback = '',
  }) {
    for (final String key in keys) {
      final String value =
          (dotenv.isInitialized ? dotenv.env[key] : null)?.trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    for (final String value in defines) {
      if (value.isNotEmpty) return value;
    }
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

  // --- Legacy CRM stored in the Leads Agent GitHub repo ---
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

  static String get crmWebUrl =>
      _read('CRM_WEB_URL', const String.fromEnvironment('CRM_WEB_URL'));

  // --- Supabase shared CRM database ---
  // Supports both Flutter-style names and the NEXT_PUBLIC names commonly used
  // by the Leads Agent web app.
  static String get supabaseUrl => _readAny(
        <String>['SUPABASE_URL', 'NEXT_PUBLIC_SUPABASE_URL'],
        <String>[
          const String.fromEnvironment('SUPABASE_URL'),
          const String.fromEnvironment('NEXT_PUBLIC_SUPABASE_URL'),
        ],
      );

  static String get supabaseAnonKey => _readAny(
        <String>[
          'SUPABASE_ANON_KEY',
          'SUPABASE_PUBLISHABLE_KEY',
          'NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY',
        ],
        <String>[
          const String.fromEnvironment('SUPABASE_ANON_KEY'),
          const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
          const String.fromEnvironment('NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY'),
        ],
      );

  // --- Trello ---
  static String get trelloKey =>
      _read('TRELLO_KEY', const String.fromEnvironment('TRELLO_KEY'));
  static String get trelloToken =>
      _read('TRELLO_TOKEN', const String.fromEnvironment('TRELLO_TOKEN'));
  static String get trelloListId =>
      _read('TRELLO_LIST_ID', const String.fromEnvironment('TRELLO_LIST_ID'));
  static String get trelloBoardUrl => _read(
        'TRELLO_BOARD_URL',
        const String.fromEnvironment('TRELLO_BOARD_URL'),
      );

  static bool get demoDirectIntegrations {
    final String raw = _read(
      'DEMO_DIRECT_INTEGRATIONS',
      const String.fromEnvironment('DEMO_DIRECT_INTEGRATIONS'),
      fallback: 'true',
    );
    return raw.toLowerCase() != 'false';
  }

  // --- Capability flags ---
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  static bool get hasGemini =>
      demoDirectIntegrations && geminiApiKey.isNotEmpty;
  static bool get hasGithubCrm => demoDirectIntegrations &&
      githubToken.isNotEmpty &&
      githubCrmRepo.isNotEmpty;
  static bool get hasCrmWeb => crmWebUrl.isNotEmpty;
  static bool get hasTrello => demoDirectIntegrations &&
      trelloKey.isNotEmpty &&
      trelloToken.isNotEmpty &&
      trelloListId.isNotEmpty;
  static bool get hasTrelloBoard => trelloBoardUrl.isNotEmpty;
}
