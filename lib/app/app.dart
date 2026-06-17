import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_constants.dart';
import '../core/get.dart';
import '../core/repository/auth_repository.dart';
import '../core/services/navigator_service.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/bloc/auth_bloc.dart';
import 'auth_gate.dart';

/// Root widget. Provides the app-wide [AuthBloc], applies the Material 3 theme,
/// and clamps text scaling so layouts stay intact at extreme accessibility
/// settings while still honouring user preferences.
class MrRexApp extends StatelessWidget {
  const MrRexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => AuthBloc(authRepository: app<AuthRepository>()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        theme: AppTheme.light,
        navigatorKey: app<NavigatorService>().navigatorKey,
        builder: (BuildContext context, Widget? child) {
          final MediaQueryData mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.25,
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const AuthGate(),
      ),
    );
  }
}
