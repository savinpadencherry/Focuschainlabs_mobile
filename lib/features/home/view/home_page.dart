import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/get.dart';
import '../../../core/repository/capture_repository.dart';
import '../../../core/repository/meeting_repository.dart';
import '../bloc/home_bloc.dart';
import 'home_view.dart';

/// Wires the [HomeBloc] and triggers the initial load. Kept separate from the
/// view so the UI stays a pure function of state.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (_) => HomeBloc(
        meetingRepository: app<MeetingRepository>(),
        captureRepository: app<CaptureRepository>(),
      )..add(const HomeLoaded()),
      child: const HomeView(),
    );
  }
}
