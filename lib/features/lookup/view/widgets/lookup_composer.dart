import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../bloc/lookup_bloc.dart';

/// The lookup input bar: a text field with send, plus a voice button (F1
/// "works by voice and by typed/tapped search").
class LookupComposer extends StatefulWidget {
  const LookupComposer({super.key, required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<LookupComposer> createState() => _LookupComposerState();
}

class _LookupComposerState extends State<LookupComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = context.select((LookupBloc b) => b.state.busy);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Ask about a client or our offering…',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _SendButton(busy: busy, onTap: _submit),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.logoGradient),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: busy
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Icon(Icons.arrow_upward_rounded, color: Colors.white),
      ),
    );
  }
}
