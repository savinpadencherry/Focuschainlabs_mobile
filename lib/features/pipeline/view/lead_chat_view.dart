import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/get.dart';
import '../../../core/models/lead_chat.dart';
import '../../../core/repository/crm_repository.dart';
import '../../../core/services/api/secona_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/crm_chips.dart';
import '../../../shared/widgets/error_view.dart';
import '../../ona/view/widgets/ona_mark.dart';
import '../bloc/pipeline_bloc.dart';
import 'widgets/lead_brief_tile.dart';
import 'widgets/lead_composer.dart';

/// Talk to Ona about one lead.
///
/// The same thing the web app's lead chat does, from the same brief: the
/// server builds the lead's context out of every table holding a piece of it
/// and gives the model only that, so an answer about what was said on a call
/// quotes the call rather than inventing one.
///
/// The thread is stored in Postgres, so it is the *same* thread as the one in
/// the browser. A question asked here is there at the desk, which is the point
/// — the desktop thread is what a rep reads before phoning.
class LeadChatView extends StatefulWidget {
  const LeadChatView({super.key, required this.leadId});

  final String leadId;

  static Future<void> open(BuildContext context, String leadId) {
    final PipelineBloc bloc = context.read<PipelineBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<PipelineBloc>.value(
          value: bloc,
          child: LeadChatView(leadId: leadId),
        ),
      ),
    );
  }

  @override
  State<LeadChatView> createState() => _LeadChatViewState();
}

class _LeadChatViewState extends State<LeadChatView> {
  final ScrollController _scroll = ScrollController();

  LeadChatThread? _thread;
  List<LeadChatMessage> _messages = <LeadChatMessage>[];
  String _error = '';
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final LeadChatThread t =
          await app<CrmRepository>().leadThread(widget.leadId);
      if (mounted) {
        setState(() {
          _thread = t;
          _messages = t.messages;
        });
        _toBottom();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _send(String text) async {
    final String question = text.trim();
    if (question.isEmpty || _busy) return;

    // The question and a thinking bubble go on screen immediately; the server
    // stores the real pair and hands them back with their ids.
    setState(() {
      _busy = true;
      _messages = <LeadChatMessage>[
        ..._messages,
        LeadChatMessage(
          id: '_local',
          role: 'user',
          body: question,
          source: 'mobile',
          createdAt: DateTime.now(),
        ),
        const LeadChatMessage.thinking(),
      ];
    });
    _toBottom();

    try {
      final List<LeadChatMessage> stored =
          await app<CrmRepository>().askAboutLead(widget.leadId, question);
      if (!mounted) return;
      setState(() {
        _messages = <LeadChatMessage>[
          ..._messages.where(
            (LeadChatMessage m) => m.id != '_local' && !m.pending,
          ),
          ...stored,
        ];
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages = _messages.where((LeadChatMessage m) => !m.pending).toList();
        _error = e.message;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
      _toBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final LeadChatThread? t = _thread;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            _TopBar(title: t?.lead.title ?? 'Lead chat', onReset: _reset),
            Expanded(
              child: _loading && t == null
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.green),
                    )
                  : (_error.isNotEmpty && _messages.isEmpty)
                      ? ErrorView(message: _error, onRetry: _load)
                      : ContentBounds(
                          maxWidth: Breakpoints.readableMaxWidth,
                          child: ListView(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                            children: <Widget>[
                              if (t != null && !t.brief.isEmpty) ...<Widget>[
                                LeadBriefTile(brief: t.brief),
                                AppSpacing.vGapLg,
                              ],
                              if (_messages.isEmpty)
                                _Starters(onTap: _send)
                              else
                                for (final LeadChatMessage m in _messages)
                                  _Bubble(message: m),
                            ],
                          ),
                        ),
            ),
            if (_error.isNotEmpty && _messages.isNotEmpty)
              _InlineError(message: _error),
            LeadComposer(
              hint: 'Ask Ona about ${t?.lead.title ?? 'this lead'}…',
              busy: _busy,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reset() async {
    await app<CrmRepository>().clearLeadThread(widget.leadId);
    if (mounted) _load();
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onReset});

  final String title;
  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const OnaMark(size: 26),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                ),
                Text(
                  'Answers from this lead’s record',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Clear thread',
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

/// What to ask when a thread is empty.
///
/// Every one of these is answerable from the brief the server builds, which is
/// why they are these four and not a generic "how can I help".
class _Starters extends StatelessWidget {
  const _Starters({required this.onTap});

  final ValueChanged<String> onTap;

  static const List<String> _prompts = <String>[
    'What did we last discuss?',
    'What are they looking for?',
    'What should I do next?',
    'What do we still not know about them?',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Ask about this lead', style: Theme.of(context).textTheme.labelLarge),
        AppSpacing.vGapSm,
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final String p in _prompts)
              TagChip(
                p,
                color: AppColors.iris,
                filled: false,
                onTap: () => onTap(p),
              ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final LeadChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.pending) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Row(
          children: <Widget>[
            OnaMark(size: 24),
            SizedBox(width: 10),
            OnaThinking(),
          ],
        ),
      );
    }

    final bool user = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            user ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          if (!user) ...<Widget>[
            const OnaMark(size: 24),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: user ? AppColors.iris : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(user ? 16 : 4),
                  bottomRight: Radius.circular(user ? 4 : 16),
                ),
                border: user ? null : Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    message.body,
                    style: TextStyle(
                      height: 1.4,
                      color: user ? Colors.white : AppColors.ink,
                    ),
                  ),
                  // Marked when it came from the browser, because a thread
                  // that suddenly contains questions you did not ask is
                  // confusing until you know where they came from.
                  if (message.fromWeb && !user) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'from the web app',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.inkMuted.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.1);
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Row(
        children: <Widget>[
          const Icon(Icons.cloud_off_rounded, size: 15, color: AppColors.negative),
          const SizedBox(width: 7),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
