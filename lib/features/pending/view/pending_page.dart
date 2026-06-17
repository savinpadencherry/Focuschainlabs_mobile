import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/get.dart';
import '../../../core/repository/capture_repository.dart';
import '../../../core/services/navigator_service.dart';
import '../bloc/pending_bloc.dart';
import 'pending_view.dart';

/// Wires the [PendingBloc] for the 'Pending capture' list (F3).
class PendingPage extends StatelessWidget {
  const PendingPage({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(AppPageRoute<void>(const PendingPage()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PendingBloc>(
      create: (_) => PendingBloc(captureRepository: app<CaptureRepository>())
        ..add(const PendingRequested()),
      child: const PendingView(),
    );
  }
}
