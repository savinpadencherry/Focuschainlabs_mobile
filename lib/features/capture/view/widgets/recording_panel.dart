import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/get.dart';
import '../../../../core/services/voice/voice_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/mono_label.dart';
import '../../bloc/capture_flow_bloc.dart';

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
  bool _listening = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _speak() async {
    setState(() => _listening = true);
    final String text = await _voice.transcribe();
    if (!mounted) return;
    final String existing = _controller.text.trim();
    _controller.text = existing.isEmpty ? text : '$existing $text';
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    setState(() => _listening = false);
  }

  void _send() {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<CaptureFlowBloc>().add(CaptureManualSubmitted(text));
  }

  @override
  Widget build(BuildContext context) {
    final String? client = widget.state.source?.clientName;
    final bool isError = widget.state.status == CaptureFlowStatus.error;

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
            'Speak or type naturally — Rex structures it and decides whether it’s '
            'a CRM update or a Trello task.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          AppSpacing.vGapLg,
          Expanded(child: _ComposerField(controller: _controller, listening: _listening)),
          if (isError) ...<Widget>[
            AppSpacing.vGapSm,
            Text(
              widget.state.message ?? 'Something went wrong — try again.',
              style: const TextStyle(color: AppColors.negative, fontSize: 13),
            ),
          ],
          AppSpacing.vGapLg,
          Row(
            children: <Widget>[
              _MicButton(listening: _listening, onTap: _listening ? null : _speak),
              const SizedBox(width: 12),
              Expanded(child: _SendButton(onTap: _send)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposerField extends StatelessWidget {
  const _ComposerField({required this.controller, required this.listening});

  final TextEditingController controller;
  final bool listening;

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
              ? 'Listening…'
              : 'e.g. “Called Acme, they want a revised quote by Friday, deal looks warm.”',
          hintStyle: const TextStyle(color: AppColors.inkMuted, height: 1.5),
        ),
        style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.ink),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.listening, required this.onTap});

  final bool listening;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            ? const Padding(
                padding: EdgeInsets.all(17),
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
            : const Icon(Icons.mic_rounded, color: AppColors.green),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}
