import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/get.dart';
import '../../../../core/services/voice/voice_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/mono_label.dart';
import '../../bloc/capture_flow_bloc.dart';

enum _MicState { idle, listening, unavailable, permissionDenied, error }

/// The capture entry surface: a premium composer where the rep **types or
/// speaks** a natural-language note, then sends it to Rex (Gemini) which
/// decides whether it becomes a CRM update or a Trello task.
class RecordingPanel extends StatefulWidget {
  const RecordingPanel({super.key, required this.state});

  final CaptureFlowState state;

  @override
  State<RecordingPanel> createState() => _RecordingPanelState();
}

class _RecordingPanelState extends State<RecordingPanel> {
  final TextEditingController _controller = TextEditingController();
  final VoiceService _voice = app<VoiceService>();

  _MicState _micState = _MicState.idle;
  String? _micMessage;
  String _committedText = '';
  String _livePartial = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final bool available = await _voice.initialize() && await _voice.isAvailable();
    if (!mounted) return;
    if (!available) {
      setState(() {
        _micState = _MicState.unavailable;
        _micMessage = 'Voice capture is not available on this device.';
      });
    }
  }

  @override
  void dispose() {
    _voice.cancelListening();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    if (_submitting) return;
    if (_micState == _MicState.listening) {
      await _voice.stopListening();
      if (!mounted) return;
      setState(() {
        _micState = _MicState.idle;
        _committedText = _controller.text.trim();
        _livePartial = '';
      });
      return;
    }

    _committedText = _controller.text.trim();
    _livePartial = '';
    setState(() {
      _micState = _MicState.listening;
      _micMessage = null;
    });

    await _voice.startListening(
      onResult: (String transcript, bool isFinal) {
        if (!mounted) return;
        setState(() {
          _livePartial = transcript;
          final String base = _committedText;
          _controller.text =
              base.isEmpty ? transcript : '$base $transcript'.trim();
          _controller.selection =
              TextSelection.collapsed(offset: _controller.text.length);
          if (isFinal) {
            _committedText = _controller.text.trim();
            _livePartial = '';
            _micState = _MicState.idle;
          }
        });
      },
      onError: (String message) {
        if (!mounted) return;
        final bool denied = message.toLowerCase().contains('permission');
        setState(() {
          _micState = denied ? _MicState.permissionDenied : _MicState.error;
          _micMessage = message;
          _livePartial = '';
        });
      },
    );
  }

  void _send() {
    if (_submitting || _micState == _MicState.listening) return;
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    _submitting = true;
    FocusScope.of(context).unfocus();
    context.read<CaptureFlowBloc>().add(CaptureManualSubmitted(text));
  }

  @override
  Widget build(BuildContext context) {
    final String? client = widget.state.source?.clientName;
    final bool isError = widget.state.status == CaptureFlowStatus.error;
    final bool listening = _micState == _MicState.listening;
    final String? statusMessage = isError
        ? widget.state.message
        : _micMessage;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MonoLabel(client == null ? 'Talk or type to Rex' : 'Capturing · $client'),
          AppSpacing.vGapMd,
          Text(
            'What happened?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          AppSpacing.vGapSm,
          Text(
            'Speak or type naturally — Rex structures it and recommends whether '
            'it’s a CRM update or a Trello task. You confirm before anything is written.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          AppSpacing.vGapLg,
          Expanded(
            child: _ComposerField(
              controller: _controller,
              listening: listening,
              partialHint: _livePartial,
            ),
          ),
          if (statusMessage != null) ...<Widget>[
            AppSpacing.vGapSm,
            Text(
              statusMessage,
              style: TextStyle(
                color: _micState == _MicState.permissionDenied ||
                        _micState == _MicState.unavailable
                    ? AppColors.atRisk
                    : AppColors.negative,
                fontSize: 13,
              ),
            ),
          ],
          AppSpacing.vGapLg,
          Row(
            children: <Widget>[
              _MicButton(
                listening: listening,
                disabled: _micState == _MicState.unavailable || _submitting,
                onTap: _toggleMic,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SendButton(
                  onTap: _send,
                  disabled: _submitting || listening,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposerField extends StatelessWidget {
  const _ComposerField({
    required this.controller,
    required this.listening,
    required this.partialHint,
  });

  final TextEditingController controller;
  final bool listening;
  final String partialHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: listening ? AppColors.green : AppColors.cardBorder,
          width: listening ? 1.6 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: -16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        expands: true,
        maxLines: null,
        minLines: null,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          hintText: listening
              ? (partialHint.isEmpty ? 'Listening…' : partialHint)
              : 'e.g. “Called Acme, they want a revised quote by Friday, deal looks warm.”',
          hintStyle: const TextStyle(color: AppColors.inkMuted, height: 1.5),
        ),
        style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.ink),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.listening,
    required this.disabled,
    required this.onTap,
  });

  final bool listening;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: listening ? AppColors.green : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: listening ? AppColors.green : AppColors.cardBorder),
            boxShadow: listening
                ? const <BoxShadow>[BoxShadow(color: AppColors.greenGlow, blurRadius: 18)]
                : null,
          ),
          child: listening
              ? const Icon(Icons.stop_rounded, color: Colors.white, size: 28)
              : const Icon(Icons.mic_rounded, color: AppColors.green),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onTap, required this.disabled});

  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.55 : 1,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.brandGradient),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: AppColors.greenGlow, blurRadius: 18, offset: Offset(0, 6)),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Send to Rex',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
