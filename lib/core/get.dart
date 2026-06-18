import 'package:get_it/get_it.dart';

import 'config/app_config.dart';
import 'repository/auth_repository.dart';
import 'repository/capture_repository.dart';
import 'repository/client_repository.dart';
import 'repository/lookup_repository.dart';
import 'repository/meeting_repository.dart';
import 'services/ai/ai_service.dart';
import 'services/ai/gemini_ai_service.dart';
import 'services/ai/mock_ai_service.dart';
import 'services/crm/github_crm_service.dart';
import 'services/crm/leads_crm_service.dart';
import 'services/crm/mock_leads_crm_service.dart';
import 'services/local_store.dart';
import 'services/navigator_service.dart';
import 'services/tasks/http_trello_service.dart';
import 'services/tasks/mock_trello_service.dart';
import 'services/tasks/trello_service.dart';
import 'services/voice/voice_service.dart';

/// Global service locator. Implementations are chosen at startup from
/// [AppConfig]: when a real key/endpoint is provided the live service is used,
/// otherwise the offline mock keeps the app fully runnable. Swapping demo ↔
/// live touches only this file.
final GetIt app = GetIt.instance;

void initializeGetIt() {
  if (app.isRegistered<NavigatorService>()) return;

  // Infra services
  app
    ..registerLazySingleton<NavigatorService>(NavigatorService.new)
    ..registerLazySingleton<LocalStore>(LocalStore.new)
    ..registerLazySingleton<VoiceService>(MockVoiceService.new);

  // AI — Gemini when a key is present, else mock.
  app.registerLazySingleton<AiService>(
    () => AppConfig.hasGemini ? GeminiAiService() : const MockAiService(),
  );

  // CRM — read/write the Leads Agent repo's contacts.json when a GitHub token
  // is configured, else mock.
  app.registerLazySingleton<LeadsCrmService>(
    () => AppConfig.hasGithubCrm ? GithubCrmService() : const MockLeadsCrmService(),
  );

  // Tasks — Trello REST when configured, else mock.
  app.registerLazySingleton<TrelloService>(
    () => AppConfig.hasTrello ? HttpTrelloService() : const MockTrelloService(),
  );

  // Repositories
  app
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepository(store: app<LocalStore>()),
    )
    ..registerLazySingleton<ClientRepository>(ClientRepository.new)
    ..registerLazySingleton<MeetingRepository>(MeetingRepository.new)
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
