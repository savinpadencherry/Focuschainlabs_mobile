import 'package:get_it/get_it.dart';

import 'config/app_config.dart';
import 'repository/auth_repository.dart';
import 'repository/capture_repository.dart';
import 'repository/client_repository.dart';
import 'repository/firebase_auth_repository.dart';
import 'repository/lookup_repository.dart';
import 'repository/meeting_repository.dart';
import 'services/ai/ai_service.dart';
import 'services/ai/gemini_ai_service.dart';
import 'services/ai/mock_ai_service.dart';
import 'services/auth/google_auth_service.dart';
import 'services/calendar/calendar_service.dart';
import 'services/calendar/google_calendar_service.dart';
import 'services/calendar/mock_calendar_service.dart';
import 'services/crm/github_crm_service.dart';
import 'services/crm/leads_crm_service.dart';
import 'services/crm/mock_leads_crm_service.dart';
import 'services/crm/supabase_crm_service.dart';
import 'services/firebase/analytics_service.dart';
import 'services/firebase/firebase_bootstrap.dart';
import 'services/local_store.dart';
import 'services/navigator_service.dart';
import 'services/reminders/reminder_service.dart';
import 'services/supabase/supabase_bootstrap.dart';
import 'services/tasks/http_trello_service.dart';
import 'services/tasks/mock_trello_service.dart';
import 'services/tasks/trello_service.dart';
import 'services/voice/device_voice_service.dart';
import 'services/voice/voice_service.dart';

/// Global service locator. Implementations are chosen at startup: Firebase
/// services activate once [FirebaseBootstrap.ready] is true (config present),
/// other integrations activate when their `.env` keys are set; otherwise the
/// offline mocks keep the app fully runnable. Swapping demo ↔ live touches only
/// this file.
final GetIt app = GetIt.instance;

void initializeGetIt() {
  if (app.isRegistered<NavigatorService>()) return;
  final bool firebase = FirebaseBootstrap.ready;

  // Infra services
  app
    ..registerLazySingleton<NavigatorService>(NavigatorService.new)
    ..registerLazySingleton<LocalStore>(LocalStore.new)
    ..registerLazySingleton<VoiceService>(DeviceVoiceService.new)
    ..registerLazySingleton<GoogleAuthService>(GoogleAuthService.new)
    ..registerLazySingleton<ReminderService>(ReminderService.new)
    ..registerLazySingleton<AnalyticsService>(
      () => firebase ? FirebaseAnalyticsService() : const NoopAnalyticsService(),
    );

  // AI — Gemini when a key is present, else mock.
  app.registerLazySingleton<AiService>(
    () => AppConfig.hasGemini ? GeminiAiService() : const MockAiService(),
  );

  // Calendar — Google Calendar when signed in via Firebase, else mock.
  app.registerLazySingleton<CalendarService>(
    () => firebase
        ? GoogleCalendarService(auth: app<GoogleAuthService>())
        : const MockCalendarService(),
  );

  // CRM — Supabase when configured (the shared database), else the GitHub repo,
  // else mock.
  app.registerLazySingleton<LeadsCrmService>(
    () => SupabaseBootstrap.ready
        ? SupabaseCrmService()
        : (AppConfig.hasGithubCrm
            ? GithubCrmService()
            : const MockLeadsCrmService()),
  );

  // Tasks — Trello REST when configured, else mock.
  app.registerLazySingleton<TrelloService>(
    () => AppConfig.hasTrello ? HttpTrelloService() : const MockTrelloService(),
  );

  // Repositories
  app
    ..registerLazySingleton<AuthRepository>(
      () => firebase
          ? FirebaseAuthRepository(
              google: app<GoogleAuthService>(),
              analytics: app<AnalyticsService>(),
            )
          : DemoAuthRepository(store: app<LocalStore>()),
    )
    ..registerLazySingleton<ClientRepository>(ClientRepository.new)
    ..registerLazySingleton<MeetingRepository>(
      () => MeetingRepository(calendar: app<CalendarService>()),
    )
    ..registerLazySingleton<CaptureRepository>(
      () => CaptureRepository(
        ai: app<AiService>(),
        store: app<LocalStore>(),
        crm: app<LeadsCrmService>(),
        trello: app<TrelloService>(),
      ),
    )
    ..registerLazySingleton<LookupRepository>(
      () => LookupRepository(
        ai: app<AiService>(),
        clients: app<ClientRepository>(),
      ),
    );
}
