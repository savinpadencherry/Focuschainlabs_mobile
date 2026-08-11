import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/models/ona.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/crm_chips.dart';
import '../../../shared/widgets/surface_header.dart';
import '../bloc/ona_bloc.dart';
import '../../pipeline/view/widgets/lead_composer.dart';
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

  @override
  void dispose() {
    _scroll.dispose();
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

  /// Something the user typed. Always goes to the model — the whole reason
  /// they typed instead of tapping is that no chip covered what they meant.
  void _sendTyped(String text) => _ask(text, fromChip: false);

  /// A chip. Carries wording the product wrote, so the server may answer it
  /// from keywords instantly.
  void _sendChip(String prompt) => _ask(prompt, fromChip: true);

  void _ask(String text, {required bool fromChip}) {
    final String query = text.trim();
    if (query.isEmpty) return;
    context.read<OnaBloc>().add(OnaAsked(query, fromChip: fromChip));
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
                            composer: LeadComposer(
                              key: const ValueKey<String>('ona-landing'),
                              hint: AppStrings.onaHint,
                              busy: state.busy,
                              onSend: _sendTyped,
                              bottomInset: 0,
                            ),
                            onChip: _sendChip,
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
                  _ThreadChips(onTap: _sendChip),
                  LeadComposer(
                    key: const ValueKey<String>('ona-thread'),
                    hint: AppStrings.onaHint,
                    busy: state.busy,
                    onSend: _sendTyped,
                    // The Scaffold already reserves the nav bar's height, so
                    // this only needs the ordinary gap.
                    bottomInset: 12,
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
