import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/get.dart';
import '../../../core/models/capture.dart';
import '../../../core/repository/capture_repository.dart';
import '../../../core/services/ai/ai_service.dart';
import '../../../core/services/crm/leads_crm_service.dart';
import '../../../core/services/navigator_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/mono_label.dart';
import '../bloc/conversation_bloc.dart';
import 'widgets/capture_result_actions.dart';
import 'widgets/conversation_bubble.dart';
import 'widgets/extraction_summary_card.dart';
import 'widgets/rex_composer.dart';

/// Conversational capture: a chat with Rex (Gemini) that asks follow-ups until
/// it has enough, then creates/updates the CRM record (or a Trello task).
class ConversationView extends StatefulWidget {
  const ConversationView({super.key});

  /// Opens the conversation, optionally pre-filled for a pending [source].
  static Future<void> open(BuildContext context, {Capture? source}) {
    return Navigator.of(context).push<void>(
      AppPageRoute<void>(
        BlocProvider<ConversationBloc>(
          create: (_) => ConversationBloc(
            ai: app<AiService>(),
            captures: app<CaptureRepository>(),
            crm: app<LeadsCrmService>(),
            source: source,
          )..add(const ConversationOpened()),
          child: const ConversationView(),
        ),
      ),
    );
  }

  @override
  State<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<ConversationView> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: <Widget>[
            const Text('Talk to Rex'),
            const SizedBox(width: 10),
            const MonoLabel('live'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'New conversation',
            onPressed: () => context.read<ConversationBloc>().add(const ConversationReset()),
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ContentBounds(
          maxWidth: Breakpoints.readableMaxWidth,
          child: BlocConsumer<ConversationBloc, ConversationState>(
            listenWhen: (ConversationState p, ConversationState c) =>
                p.messages.length != c.messages.length ||
                p.status != c.status,
            listener: (BuildContext context, ConversationState state) {
              _scrollToEnd();
              if (state.status == ConversationStatus.undone) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(content: Text('Update reverted.')));
                Navigator.of(context).maybePop();
              }
            },
            builder: (BuildContext context, ConversationState state) {
              return Column(
                children: <Widget>[
                  Expanded(child: _Thread(scroll: _scroll, state: state)),
                  if (state.isWritten)
                    _WrittenBar(state: state)
                  else
                    RexComposer(
                      onSend: (String t) =>
                          context.read<ConversationBloc>().add(ConversationSent(t)),
                      enabled: !state.busy && !state.isWritten,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Thread extends StatelessWidget {
  const _Thread({required this.scroll, required this.state});

  final ScrollController scroll;
  final ConversationState state;

  @override
  Widget build(BuildContext context) {
    final bool showCard = (state.isReady || state.status == ConversationStatus.writing) &&
        state.extraction != null;
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      children: <Widget>[
        for (final m in state.messages)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ConversationBubble(message: m),
          ),
        if (showCard)
          ExtractionSummaryCard(
            extraction: state.extraction!,
            saving: state.status == ConversationStatus.writing,
            onSave: () =>
                context.read<ConversationBloc>().add(const ConversationConfirmed()),
          ),
        if (state.isWritten && state.activityEntry != null) ...<Widget>[
          const SizedBox(height: 8),
          _SavedHeader(isTask: state.activityEntry!.isTask),
          const SizedBox(height: 14),
          CaptureResultActions(entry: state.activityEntry!),
        ],
      ],
    );
  }
}

class _SavedHeader extends StatelessWidget {
  const _SavedHeader({required this.isTask});

  final bool isTask;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(Icons.check_circle_rounded, color: AppColors.positive),
        const SizedBox(width: 8),
        Text(
          isTask ? 'Saved · Trello updated' : 'Saved to the CRM',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ],
    );
  }
}

class _WrittenBar extends StatelessWidget {
  const _WrittenBar({required this.state});

  final ConversationState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context
                  .read<ConversationBloc>()
                  .add(const ConversationUndoRequested()),
              icon: const Icon(Icons.undo_rounded),
              label: const Text('Undo'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
