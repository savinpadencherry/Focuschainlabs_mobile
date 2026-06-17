import 'package:get_it/get_it.dart';

import 'services/navigator_service.dart';

final GetIt app = GetIt.instance;

void initializeGetIt() {
  if (!app.isRegistered<NavigatorService>()) {
    app.registerLazySingleton<NavigatorService>(NavigatorService.new);
  }
}
