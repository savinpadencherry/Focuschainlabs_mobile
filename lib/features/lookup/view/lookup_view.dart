import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../bloc/lookup_bloc.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/lookup_composer.dart';
import 'widgets/lookup_empty.dart';

/// The F1 conversational lookup screen: an empty-state of suggestions until the
/// first question, then a grounded, cited chat thread.
class LookupView extends StatefulWidget {
  const LookupView({super.key});

  @override
  State<LookupView> createState() => _LookupViewState();
}

class _LookupViewState extends State<LookupView> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _ask(String query) {
    context.read<LookupBloc>().add(LookupAsked(query));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 240,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask Rex'),
        actions: <Widget>[
          BlocBuilder<LookupBloc, LookupState>(
            builder: (BuildContext context, LookupState state) {
              if (state.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'New lookup',
                onPressed: () =>
                    context.read<LookupBloc>().add(const LookupCleared()),
                icon: const Icon(Icons.add_comment_outlined),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ContentBounds(
          maxWidth: Breakpoints.readableMaxWidth,
          child: Column(
            children: <Widget>[
              Expanded(
                child: BlocBuilder<LookupBloc, LookupState>(
                  builder: (BuildContext context, LookupState state) {
                    if (state.isEmpty) {
                      return LookupEmpty(onSuggestion: _ask);
                    }
                    return ListView.separated(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      itemCount: state.messages.length,
                      separatorBuilder: (_, __) => AppSpacing.vGapLg,
                      itemBuilder: (BuildContext context, int i) =>
                          ChatBubble(message: state.messages[i]),
                    );
                  },
                ),
              ),
              _GroundingHint(),
              LookupComposer(onSubmit: _ask),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroundingHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.shield_outlined, size: 13, color: AppColors.textMuted),
          SizedBox(width: 5),
          Text(
            'Grounded in your org’s data · nothing invented',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
