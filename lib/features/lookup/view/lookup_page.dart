import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/get.dart';
import '../../../core/repository/lookup_repository.dart';
import '../../../core/services/navigator_service.dart';
import '../bloc/lookup_bloc.dart';
import 'lookup_view.dart';

/// Wires the [LookupBloc] for the conversational lookup (F1).
class LookupPage extends StatelessWidget {
  const LookupPage({super.key});

  /// Pushes the lookup screen with its own bloc scope.
  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(AppPageRoute<void>(const LookupPage()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LookupBloc>(
      create: (_) => LookupBloc(repository: app<LookupRepository>()),
      child: const LookupView(),
    );
  }
}
