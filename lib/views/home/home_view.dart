import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/blocs/capture/capture_bloc.dart';
import '../capture/capture_view.dart';
import '../lookup/lookup_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mr. Rex')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context, const CaptureView()),
        icon: const Icon(Icons.mic),
        label: const Text('Talk to Rex'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Ask about a client or offering'),
              subtitle: const Text('What is the latest on Acme?'),
              onTap: () => _open(context, const LookupView()),
            ),
          ),
          const SizedBox(height: 24),
          Text('Pending captures', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          BlocBuilder<CaptureBloc, CaptureState>(
            builder: (BuildContext context, CaptureState state) {
              if (state is CaptureLoaded) {
                return Column(
                  children: state.captures
                      .map(
                        (item) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.mic_none),
                            title: Text(item.clientName),
                            subtitle: Text(item.summary),
                            onTap: () => _open(context, const CaptureView()),
                          ),
                        ),
                      )
                      .toList(),
                );
              }
              if (state is CaptureFailure) {
                return Text(state.message);
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ],
      ),
    );
  }

  static Future<void> _open(BuildContext context, Widget view) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => view),
    );
  }
}
