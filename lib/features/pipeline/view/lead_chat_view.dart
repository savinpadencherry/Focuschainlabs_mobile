import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/pipeline.dart';
import '../../../core/services/voice/voice_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/crm_chips.dart';
import '../bloc/pipeline_bloc.dart';
import 'widgets/lead_sheet.dart';

/// A lead's chat: the timeline, and a microphone to add to it.
///
/// This is the loop the whole app exists for — walk out of a meeting, hold the
/// mic, say what happened, confirm, and it is on the record for everyone. The
/// alternative is typing it later, which means not typing it.
///
/// Dictation never writes on its own. The transcript lands in the box as
/// editable text and the rep presses Log; recognisers mishear names and prices,
/// and a note that silently records the wrong number is worse than no note.
class LeadChatView extends StatefulWidget {
  const LeadChatView({super.key, required this.leadId});

  final String leadId;

  static Future<void> open(BuildContext context, String leadId) {
    final PipelineBloc bloc = context.read<PipelineBloc>()
      ..add(PipelineLeadOpened(leadId));
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
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final VoiceService _voice = VoiceService();

  bool _listening = false;
  String _voiceError = '';

  /// What was in the box before dictation started, so speech appends to a
  /// half-typed note instead of wiping it.
  String _base = '';

  @override
  void dispose() {
    _voice.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _voice.stop();
      setState(() => _listening = false);
      return;
    }

    setState(() => _voiceError = '');
    _base = _input.text.trim();

    final bool started = await _voice.start(
      onResult: (String text, bool isFinal) {
        if (!mounted) return;
        final String joined = _base.isEmpty ? text : '$_base $text';
        _input.value = TextEditingValue(
          text: joined,
          selection: TextSelection.collapsed(offset: joined.length),
        );
        if (isFinal) setState(() => _listening = false);
      },
    );

    if (!mounted) return;
    setState(() {
      _listening = started;
      _voiceError = started
          ? ''
          : 'This phone will not start dictation. Check the microphone '
              'permission, or type the note instead.';
    });
  }

  Future<void> _log() async {
    final String note = _input.text.trim();
    if (note.isEmpty) return;
    await _voice.cancel();
    if (!mounted) return;
    setState(() => _listening = false);
    context.read<PipelineBloc>().add(PipelineNoteLogged(widget.leadId, note));
    _input.clear();
    FocusScope.of(context).unfocus();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<PipelineBloc, PipelineState>(
          listener: (BuildContext context, PipelineState state) => _toBottom(),
          builder: (BuildContext context, PipelineState state) {
            final Lead? lead = state.openLead;
            if (lead == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.green),
              );
            }
            return Column(
              children: <Widget>[
                _Header(lead: lead),
                if (state.leadBusy)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: AppColors.green,
                    backgroundColor: Colors.transparent,
                  ),
                Expanded(
                  child: ContentBounds(
                    child: _Timeline(lead: lead, controller: _scroll),
                  ),
                ),
                if (_voiceError.isNotEmpty) _VoiceError(message: _voiceError),
                _Composer(
                  controller: _input,
                  listening: _listening,
                  busy: state.leadBusy,
                  onMic: _toggleMic,
                  onLog: _log,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 8),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  lead.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                ),
                if (lead.subtitle.isNotEmpty)
                  Text(
                    lead.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StageChip(lead.stage),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Lead details',
            onPressed: () => LeadSheet.open(context, lead.id),
            icon: const Icon(Icons.info_outline_rounded, size: 21),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.lead, required this.controller});

  final Lead lead;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    if (lead.activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_none_rounded,
                    size: 34, color: AppColors.green),
              ),
              AppSpacing.vGapLg,
              Text(
                'Nothing logged yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              AppSpacing.vGapSm,
              Text(
                'Hold the microphone and say what happened. You can edit it '
                'before it is saved.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Oldest first — a timeline reads down, and the newest entry ends up next
    // to the box that just created it.
    final List<LeadActivity> entries = lead.activities.reversed.toList();

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      itemCount: entries.length,
      itemBuilder: (BuildContext context, int i) {
        return _Entry(activity: entries[i])
            .animate()
            .fadeIn(duration: 240.ms)
            .slideY(begin: 0.1, curve: Curves.easeOutCubic);
      },
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.activity});

  final LeadActivity activity;

  static String _when(DateTime? dt) {
    if (dt == null) return '';
    final Duration ago = DateTime.now().difference(dt.toLocal());
    if (ago.inMinutes < 1) return 'just now';
    if (ago.inMinutes < 60) return '${ago.inMinutes}m ago';
    if (ago.inHours < 24) return '${ago.inHours}h ago';
    if (ago.inDays < 30) return '${ago.inDays}d ago';
    return dt.toLocal().toString().split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final bool byPerson = activity.actorType == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: byPerson ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: byPerson ? AppColors.navy : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(byPerson ? 16 : 4),
              bottomRight: Radius.circular(byPerson ? 4 : 16),
            ),
            border: byPerson ? null : Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                activity.label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: byPerson
                      ? Colors.white.withValues(alpha: 0.65)
                      : AppColors.inkMuted,
                ),
              ),
              if (activity.note.isNotEmpty) ...<Widget>[
                const SizedBox(height: 3),
                Text(
                  activity.note,
                  style: TextStyle(
                    height: 1.35,
                    color: byPerson ? Colors.white : AppColors.ink,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                _when(activity.createdAt),
                style: TextStyle(
                  fontSize: 10.5,
                  color: byPerson
                      ? Colors.white.withValues(alpha: 0.55)
                      : AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceError extends StatelessWidget {
  const _VoiceError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.atRisk.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.mic_off_rounded, size: 16, color: AppColors.atRisk),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.listening,
    required this.busy,
    required this.onMic,
    required this.onLog,
  });

  final TextEditingController controller;
  final bool listening;
  final bool busy;
  final VoidCallback onMic;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(color: AppColors.paper),
      child: ContentBounds(
        child: Column(
          children: <Widget>[
            if (listening) const _ListeningBanner(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                _MicButton(listening: listening, onTap: onMic),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: listening
                          ? 'Listening…'
                          : 'Say or type what happened',
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      border: _border(AppColors.cardBorder),
                      enabledBorder: _border(AppColors.cardBorder),
                      focusedBorder: _border(AppColors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (BuildContext context, TextEditingValue value, _) {
                    final bool can = value.text.trim().isNotEmpty && !busy;
                    return SizedBox(
                      height: 46,
                      child: FilledButton(
                        onPressed: can ? onLog : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusPill),
                          ),
                        ),
                        child: const Text('Log'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        borderSide: BorderSide(color: color),
      );
}

class _ListeningBanner extends StatelessWidget {
  const _ListeningBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.negative,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
              .fadeIn(duration: 700.ms, begin: 0.25),
          const SizedBox(width: 8),
          Text(
            'Listening — tap the mic to stop',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.listening, required this.onTap});

  final bool listening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: listening ? AppColors.negative : AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: listening ? AppColors.negative : AppColors.cardBorderStrong,
            width: 1.5,
          ),
          boxShadow: listening
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.negative.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Icon(
          listening ? Icons.stop_rounded : Icons.mic_rounded,
          color: listening ? Colors.white : AppColors.ink,
          size: 22,
        ),
      ),
    );
  }
}
