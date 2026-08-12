import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/get.dart';
import '../../../../core/services/firebase/analytics_service.dart';
import '../../../../core/services/voice/voice_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';

/// The ask box: one rounded surface with the mic and the send button inside it.
///
/// The first version put the button outside the field, which is why it read as
/// two controls that happened to be next to each other. Every assistant people
/// already use — Claude, ChatGPT, Perplexity — puts the actions inside the
/// field, so the whole thing is one object you type into and then press. That
/// is also what lets the field grow to four lines without the button drifting
/// away from it.
///
/// Send is disabled until there is something to send, and it is the only
/// control that changes colour — a row of equally bright buttons gives no clue
/// which one finishes the job.
class LeadComposer extends StatefulWidget {
  const LeadComposer({
    super.key,
    required this.hint,
    required this.busy,
    required this.onSend,
    this.bottomInset = 12,
  });

  final String hint;
  final bool busy;
  final ValueChanged<String> onSend;

  /// Extra space under the box, on top of the system inset. Callers that sit
  /// above their own bar add its height here.
  final double bottomInset;

  @override
  State<LeadComposer> createState() => _LeadComposerState();
}

class _LeadComposerState extends State<LeadComposer> {
  final TextEditingController _input = TextEditingController();
  final VoiceService _voice = VoiceService();

  bool _listening = false;
  String _base = '';

  @override
  void dispose() {
    _voice.cancel();
    _input.dispose();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _voice.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
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
    app<AnalyticsService>().log(
      started
          ? AnalyticsEvents.dictationStarted
          : AnalyticsEvents.dictationUnavailable,
    );
    if (mounted) setState(() => _listening = started);
  }

  void _send() {
    final String text = _input.text.trim();
    if (text.isEmpty || widget.busy) return;
    _voice.cancel();
    setState(() => _listening = false);
    widget.onSend(text);
    _input.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final bool keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    // The gesture pill or the three-button bar sits under the window, and on a
    // pushed full-screen route nothing else is reserving that space — the box
    // was drawn underneath it and the last line of a typed note was covered.
    // Zero when the keyboard is up, because the keyboard replaces it.
    final double systemBottom =
        keyboardUp ? 0 : MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        (keyboardUp ? 10 : widget.bottomInset) + systemBottom,
      ),
      child: ContentBounds(
        maxWidth: Breakpoints.readableMaxWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_listening) const _ListeningBanner(),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(
                  color: _listening ? AppColors.negative : AppColors.cardBorder,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.iris.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                    spreadRadius: -6,
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
              child: Column(
                children: <Widget>[
                  TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(fontSize: 15.5, height: 1.35),
                    decoration: InputDecoration(
                      hintText: _listening ? 'Listening…' : widget.hint,
                      hintMaxLines: 1,
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      _CircleAction(
                        icon: _listening
                            ? Icons.stop_rounded
                            : Icons.mic_none_rounded,
                        tooltip: _listening ? 'Stop' : 'Dictate',
                        active: _listening,
                        onTap: _toggleMic,
                      ),
                      const Spacer(),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _input,
                        builder: (BuildContext context, TextEditingValue v, _) {
                          final bool can =
                              v.text.trim().isNotEmpty && !widget.busy;
                          return _SendButton(enabled: can, busy: widget.busy, onTap: _send);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: active
                ? AppColors.negative.withValues(alpha: 0.12)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: active ? AppColors.negative : AppColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: enabled ? AppColors.iris : AppColors.paper3,
          shape: BoxShape.circle,
          boxShadow: enabled
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.iris.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: busy
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  Icons.arrow_upward_rounded,
                  size: 19,
                  color: enabled ? Colors.white : AppColors.inkMuted,
                ),
        ),
      ),
    );
  }
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
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.negative,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
              .fadeIn(duration: 700.ms, begin: 0.25),
          const SizedBox(width: 8),
          Text(
            'Listening — tap stop when you are done',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
