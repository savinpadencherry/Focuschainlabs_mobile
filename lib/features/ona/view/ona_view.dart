import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/models/ona.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/crm_chips.dart';
import '../../../shared/widgets/surface_header.dart';
import '../bloc/ona_bloc.dart';
import 'widgets/ona_bubble.dart';
import 'widgets/ona_landing.dart';
import 'widgets/ona_mark.dart';

/// Ask Ona.
///
/// Two states, not one. Before anything is asked it is a landing screen — the
/// ask box in the middle of the page with the day laid out beneath it. Once a
/// question is asked it becomes a thread and the box docks to the bottom,
/// where a chat input belongs. Trying to be both at once is what made the
/// first version a chat bubble stranded above a screen of empty paper.
class OnaView extends StatefulWidget {
  const OnaView({super.key});

  @override
  State<OnaView> createState() => _OnaViewState();
}

class _OnaViewState extends State<OnaView> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _send([String? chipPrompt]) {
    final String query = (chipPrompt ?? _input.text).trim();
    if (query.isEmpty) return;
    context.read<OnaBloc>().add(OnaAsked(query, fromChip: chipPrompt != null));
    _input.clear();
    FocusScope.of(context).unfocus();
  }

  /// The opening brief, when that is still all there is.
  OnaAnswer? _brief(OnaState state) {
    if (state.turns.length != 1) return null;
    final List<OnaAnswer> answers = state.turns.first.answers;
    return answers.isEmpty ? null : answers.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      // The keyboard is handled per-state: the landing scrolls, the thread
      // docks its composer above the inset.
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<OnaBloc, OnaState>(
          listener: (BuildContext context, OnaState state) {
            if (state.turns.length > 1) _toBottom();
          },
          builder: (BuildContext context, OnaState state) {
            // A single turn means nothing has been asked yet — that turn is
            // the brief the surface opens with.
            final bool landing = state.turns.length <= 1 && !state.busy;

            return Column(
              children: <Widget>[
                SurfaceHeader(
                  leading: const _OnaLockup(),
                  trailing: state.turns.length > 1
                      ? IconButton(
                          tooltip: 'New thread',
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              context.read<OnaBloc>().add(const OnaCleared()),
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                        )
                      : null,
                ),
                Expanded(
                  child: ContentBounds(
                    child: landing
                        ? OnaLanding(
                            brief: _brief(state),
                            composer: _Composer(
                              controller: _input,
                              busy: state.busy,
                              onSend: _send,
                              elevated: true,
                            ),
                            onChip: _send,
                          )
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                            itemCount: state.turns.length,
                            itemBuilder: (BuildContext context, int i) {
                              return OnaBubble(turn: state.turns[i])
                                  .animate()
                                  .fadeIn(duration: 260.ms)
                                  .slideY(
                                    begin: 0.14,
                                    curve: Curves.easeOutCubic,
                                  );
                            },
                          ),
                  ),
                ),
                if (!landing) ...<Widget>[
                  _ThreadChips(onTap: _send),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: ContentBounds(
                      child: _Composer(
                        controller: _input,
                        busy: state.busy,
                        onSend: _send,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OnaLockup extends StatelessWidget {
  const _OnaLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const OnaMark(size: 30),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              AppStrings.onaTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
            ),
            Text(
              'Your desk, out loud',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

/// Follow-up chips, once a thread is running.
class _ThreadChips extends StatelessWidget {
  const _ThreadChips({required this.onTap});

  final ValueChanged<String> onTap;

  static const List<(String, String)> _chips = <(String, String)>[
    ('Today', 'Give me today\'s briefing'),
    ('Follow-ups', 'What follow-ups are due?'),
    ('At risk', 'Which deals are at risk?'),
    ('Pipeline', 'Pipeline summary'),
    ('Properties', 'Show me available properties'),
  ];

  @override
  Widget build(BuildContext context) {
    final bool busy = context.select((OnaBloc b) => b.state.busy);
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: <Widget>[
          for (final (String label, String prompt) in _chips)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: TagChip(
                label,
                color: AppColors.navy,
                filled: false,
                onTap: busy ? null : () => onTap(prompt),
              ),
            ),
        ],
      ),
    );
  }
}

/// The ask box.
///
/// [elevated] is the landing form: taller, shadowed, and the visual centre of
/// the screen. The docked form is flatter because on a thread it is a tool,
/// not the subject.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.busy,
    required this.onSend,
    this.elevated = false,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: elevated
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.13),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                  spreadRadius: -8,
                ),
              ],
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: TextStyle(fontSize: elevated ? 15.5 : 15),
              decoration: InputDecoration(
                hintText: AppStrings.onaHint,
                isDense: true,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: elevated ? 18 : 14,
                ),
                border: _border(AppColors.cardBorder),
                enabledBorder: _border(AppColors.cardBorder),
                focusedBorder: _border(AppColors.green),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(busy: busy, onSend: onSend, size: elevated ? 52 : 46),
        ],
      ),
    );
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        borderSide: BorderSide(color: color),
      );
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.busy,
    required this.onSend,
    this.size = 46,
  });

  final bool busy;
  final VoidCallback onSend;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onSend,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: busy
                ? <Color>[AppColors.inkMuted, AppColors.inkMuted]
                : AppColors.logoGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: busy
              ? null
              : <BoxShadow>[
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.38),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  Icons.arrow_upward_rounded,
                  size: size * 0.44,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}
