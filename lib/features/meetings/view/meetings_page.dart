import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/get.dart';
import '../../../core/repository/meeting_repository.dart';
import '../bloc/meetings_bloc.dart';
import 'meetings_view.dart';

/// Wires the [MeetingsBloc] and loads the day's meetings (F3).
class MeetingsPage extends StatelessWidget {
  const MeetingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MeetingsBloc>(
      create: (_) => MeetingsBloc(meetingRepository: app<MeetingRepository>())
        ..add(const MeetingsRequested()),
      child: const MeetingsView(),
    );
  }
}
