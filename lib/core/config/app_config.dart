/// Runtime configuration sourced from `--dart-define` values, so secrets and
/// endpoints stay out of source control. Anything left blank falls back to the
/// offline mock implementations, so the app still runs with zero setup.
///
/// Example run:
/// ```
/// flutter run \
///   --dart-define=GEMINI_API_KEY=xxx \
///   --dart-define=CRM_API_BASE_URL=https://fcl-crm-api.onrender.com \
///   --dart-define=CRM_API_TOKEN=yyy \
///   --dart-define=CRM_WEB_URL=https://fcl-leads.streamlit.app \
///   --dart-define=TRELLO_KEY=aaa --dart-define=TRELLO_TOKEN=bbb \
///   --dart-define=TRELLO_LIST_ID=66xx --dart-define=TRELLO_BOARD_URL=https://trello.com/b/xxxx
/// ```
abstract final class AppConfig {
  // --- AI (Gemini direct, per decision) ---
  static const String geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String geminiModel =
      String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-2.5-flash');

  // --- Leads Agent CRM API (FastAPI on Render) ---
  static const String crmApiBaseUrl =
      String.fromEnvironment('CRM_API_BASE_URL', defaultValue: '');
  static const String crmApiToken =
      String.fromEnvironment('CRM_API_TOKEN', defaultValue: '');

  /// The Streamlit CRM URL opened in the in-app webview (desktop view).
  static const String crmWebUrl =
      String.fromEnvironment('CRM_WEB_URL', defaultValue: '');

  // --- Trello (direct from app, per decision) ---
  static const String trelloKey =
      String.fromEnvironment('TRELLO_KEY', defaultValue: '');
  static const String trelloToken =
      String.fromEnvironment('TRELLO_TOKEN', defaultValue: '');
  static const String trelloListId =
      String.fromEnvironment('TRELLO_LIST_ID', defaultValue: '');
  static const String trelloBoardUrl =
      String.fromEnvironment('TRELLO_BOARD_URL', defaultValue: '');

  // --- Capability flags ---
  static bool get hasGemini => geminiApiKey.isNotEmpty;
  static bool get hasCrmApi => crmApiBaseUrl.isNotEmpty;
  static bool get hasCrmWeb => crmWebUrl.isNotEmpty;
  static bool get hasTrello =>
      trelloKey.isNotEmpty && trelloToken.isNotEmpty && trelloListId.isNotEmpty;
  static bool get hasTrelloBoard => trelloBoardUrl.isNotEmpty;
}
