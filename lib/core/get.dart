import 'package:get_it/get_it.dart';

import 'repository/auth_repository.dart';
import 'repository/crm_repository.dart';
import 'repository/firebase_auth_repository.dart';
import 'services/api/secona_api.dart';
import 'services/auth/google_auth_service.dart';
import 'services/firebase/analytics_service.dart';
import 'services/firebase/firebase_bootstrap.dart';
import 'services/local_store.dart';
import 'services/navigator_service.dart';

/// Global service locator.
///
/// There are no mock implementations to swap in any more. This app is a client
/// for one shared CRM, and a demo mode that invents leads would be worse than
/// an error message: a rep cannot tell seeded data from their real pipeline
/// until they act on it. When the backend is unreachable the surfaces say so.
final GetIt app = GetIt.instance;

void initializeGetIt() {
  if (app.isRegistered<NavigatorService>()) return;
  final bool firebase = FirebaseBootstrap.ready;

  app
    ..registerLazySingleton<NavigatorService>(NavigatorService.new)
    ..registerLazySingleton<LocalStore>(LocalStore.new)
    ..registerLazySingleton<GoogleAuthService>(GoogleAuthService.new)
    ..registerLazySingleton<AnalyticsService>(
      () => firebase ? FirebaseAnalyticsService() : const NoopAnalyticsService(),
    )
    ..registerLazySingleton<SeconaApi>(SeconaApi.new)
    ..registerLazySingleton<CrmRepository>(
      () => CrmRepository(api: app<SeconaApi>()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => FirebaseAuthRepository(
        google: app<GoogleAuthService>(),
        analytics: app<AnalyticsService>(),
      ),
    );
}
