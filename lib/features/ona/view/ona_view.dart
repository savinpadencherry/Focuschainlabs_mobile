import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/crm_chips.dart';
import '../../../shared/widgets/shimmer.dart';
import '../../../shared/widgets/surface_header.dart';
import '../bloc/ona_bloc.dart';
import 'widgets/ona_bubble.dart';
import 'widgets/ona_mark.dart';

/// Ask Ona.
///
/// Opens with the morning brief rather than a blinking cursor: the brief is
/// what a rep opens the app for, and an empty box asks them to think of
/// something before it will help them.
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
    // After the frame, so the new bubble has been laid out and its height is
    // known — otherwise this scrolls to where the list ended a frame ago.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<OnaBloc, OnaState>(
          listener: (BuildContext context, OnaState state) => _toBottom(),
          builder: (BuildContext context, OnaState state) {
            return Column(
              children: <Widget>[
                SurfaceHeader(
                  leading: const _OnaLockup(),
                  trailing: IconButton(
                    tooltip: 'New thread',
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        context.read<OnaBloc>().add(const OnaCleared()),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                  ),
                ),
                Expanded(
                  child: state.turns.isEmpty && state.status == OnaStatus.loading
                      ? const _BriefSkeleton()
                      : ContentBounds(
                          child: ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
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
                _Suggestions(onTap: _send),
                _Composer(
                  controller: _input,
                  busy: state.busy,
                  onSend: _send,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The mark plus the wordmark, breathing gently.
///
/// A slow pulse on the mark is the only ambient motion in the app — it marks
/// Ona as the one surface that is a conversation rather than a list.
class _OnaLockup extends StatelessWidget {
  const _OnaLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const OnaMark(size: 32)
            .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.06, 1.06),
              duration: 2200.ms,
              curve: Curves.easeInOut,
            ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              AppStrings.onaTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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

/// The brief's shape while it loads.
class _BriefSkeleton extends StatelessWidget {
  const _BriefSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: const <Widget>[
                SkeletonBar(width: 26, height: 26, radius: 13),
                SizedBox(width: 10),
                Expanded(child: SkeletonBar(height: 14)),
              ],
            ),
            const SizedBox(height: 12),
            const SkeletonBar(width: 240),
            const SizedBox(height: 8),
            const SkeletonBar(width: 180),
            const SizedBox(height: 18),
            Row(
              children: const <Widget>[
                Expanded(child: SkeletonBar(height: 66, radius: 14)),
                SizedBox(width: 8),
                Expanded(child: SkeletonBar(height: 66, radius: 14)),
                SizedBox(width: 8),
                Expanded(child: SkeletonBar(height: 66, radius: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Starter chips.
///
/// These carry wording the product wrote, so they take the fast keyword path
/// server-side and answer instantly. That is why they are sent with
/// `fromChip: true` and typed text is not.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onTap});

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
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: <Widget>[
          for (int i = 0; i < _chips.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: TagChip(
                _chips[i].$1,
                color: AppColors.navy,
                filled: false,
                onTap: busy ? null : () => onTap(_chips[i].$2),
              )
                  .animate(delay: (120 + i * 60).ms)
                  .fadeIn(duration: 260.ms)
                  .slideX(begin: 0.25, curve: Curves.easeOutCubic),
            ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.busy,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final bool keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Padding(
      // Clears the floating nav bar when the keyboard is down, and sits on the
      // keyboard when it is up.
      padding: EdgeInsets.fromLTRB(16, 10, 16, keyboardUp ? 12 : 92),
      child: ContentBounds(
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
                decoration: InputDecoration(
                  hintText: AppStrings.onaHint,
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  border: _border(AppColors.cardBorder),
                  enabledBorder: _border(AppColors.cardBorder),
                  focusedBorder: _border(AppColors.green),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(busy: busy, onSend: onSend),
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

class _SendButton extends StatelessWidget {
  const _SendButton({required this.busy, required this.onSend});

  final bool busy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onSend,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: 48,
        height: 48,
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
              : const Icon(
                  Icons.arrow_upward_rounded,
                  size: 21,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}
