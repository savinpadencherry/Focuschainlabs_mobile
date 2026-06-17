import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/blocs/auth/auth_bloc.dart';
import 'core/blocs/capture/capture_bloc.dart';
import 'core/constants.dart';
import 'core/get.dart';
import 'core/repository/auth_repository.dart';
import 'core/repository/capture_repository.dart';
import 'core/services/navigator_service.dart';
import 'theme/theme.dart';
import 'views/home/home_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeGetIt();
  runApp(const MainApplication());
}

class MainApplication extends StatelessWidget {
  const MainApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<dynamic>>[
        RepositoryProvider<AuthRepository>(
          create: (_) => AuthRepository(),
        ),
        RepositoryProvider<CaptureRepository>(
          create: (_) => CaptureRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<AuthBloc>(
            create: (BuildContext context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            )..add(const AuthStarted()),
          ),
          BlocProvider<CaptureBloc>(
            create: (BuildContext context) => CaptureBloc(
              captureRepository: context.read<CaptureRepository>(),
            )..add(const CaptureRequested()),
          ),
        ],
        child: MaterialApp(
          title: ConstantVars.appName,
          debugShowCheckedModeBanner: false,
          navigatorKey: app<NavigatorService>().navigatorKey,
          theme: AppTheme.light,
          home: const HomeView(),
        ),
      ),
    );
  }
}
