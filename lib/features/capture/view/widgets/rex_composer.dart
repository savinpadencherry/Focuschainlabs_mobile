import 'package:flutter/material.dart';

import '../../../../core/get.dart';
import '../../../../core/services/voice/voice_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// The conversation input bar: type or hold-to-speak (live partial transcripts
/// stream into the field), then send to Rex.
class RexComposer extends StatefulWidget {
  const RexComposer({super.key, required this.onSend, this.enabled = true});

  final ValueChanged<String> onSend;
  final bool enabled;

  @override
  State<RexComposer> createState() => _RexComposerState();
}

class _RexComposerState extends State<RexComposer> {
  final TextEditingController _controller = TextEditingController();
  final VoiceService _voice = app<VoiceService>();
  bool _listening = false;
  String _base = '';

  @override
  void dispose() {
    _voice.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await _voice.stop();
      return;
    }
    FocusScope.of(context).unfocus();
    final bool ok = await _voice.available();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Microphone unavailable — please type.'),
        ));
      }
      return;
    }
    _base = _controller.text.trim();
    setState(() => _listening = true);
    await _voice.listen(
      onResult: (VoiceResult r) {
        if (!mounted) return;
        final String joined = _base.isEmpty ? r.text : '$_base ${r.text}';
        _controller.value = TextEditingValue(
          text: joined,
          selection: TextSelection.collapsed(offset: joined.length),
        );
      },
      onDone: () {
        if (mounted) setState(() => _listening = false);
      },
    );
  }

  void _send() {
    final String text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
    _base = '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.viewInsetsOf(context).bottom + 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: <Widget>[
          _CircleButton(
            icon: _listening ? Icons.stop_rounded : Icons.mic_rounded,
            filled: _listening,
            onTap: widget.enabled ? _toggleListen : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: widget.enabled,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: _listening ? 'Listening…' : 'Message Rex…',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _CircleButton(
            icon: Icons.arrow_upward_rounded,
            filled: true,
            onTap: widget.enabled ? _send : null,
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.filled, this.onTap});

  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: filled ? const LinearGradient(colors: AppColors.brandGradient) : null,
          color: filled ? null : AppColors.surfaceMuted,
          shape: BoxShape.circle,
          boxShadow: filled
              ? const <BoxShadow>[BoxShadow(color: AppColors.greenGlow, blurRadius: 14)]
              : null,
        ),
        child: Icon(icon, color: filled ? Colors.white : AppColors.green, size: 22),
      ),
    );
  }
}
