import 'package:get_it/get_it.dart';

import 'repository/auth_repository.dart';
import 'repository/capture_repository.dart';
import 'repository/client_repository.dart';
import 'repository/lookup_repository.dart';
import 'repository/meeting_repository.dart';
import 'services/ai/ai_service.dart';
import 'services/ai/mock_ai_service.dart';
import 'services/local_store.dart';
import 'services/navigator_service.dart';
import 'services/voice/voice_service.dart';

/// Global service locator. Services and repositories are registered here once
/// and resolved everywhere via [app], keeping widgets free of construction
/// logic. To go live, swap [MockAiService]/[MockVoiceService] for the real
/// implementations — nothing else changes.
final GetIt app = GetIt.instance;

void initializeGetIt() {
  if (app.isRegistered<NavigatorService>()) return;

  // Services
  app
    ..registerLazySingleton<NavigatorService>(NavigatorService.new)
    ..registerLazySingleton<LocalStore>(LocalStore.new)
    ..registerLazySingleton<AiService>(MockAiService.new)
    ..registerLazySingleton<VoiceService>(MockVoiceService.new);

  // Repositories
  app
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepository(store: app<LocalStore>()),
    )
    ..registerLazySingleton<ClientRepository>(ClientRepository.new)
    ..registerLazySingleton<MeetingRepository>(MeetingRepository.new)
    ..registerLazySingleton<CaptureRepository>(
      () => CaptureRepository(ai: app<AiService>(), store: app<LocalStore>()),
    )
    ..registerLazySingleton<LookupRepository>(
      () => LookupRepository(
        ai: app<AiService>(),
        clients: app<ClientRepository>(),
      ),
    );
}
