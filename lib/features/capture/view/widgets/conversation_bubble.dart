import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/models/conversation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../lookup/view/widgets/typing_dots.dart';

/// A single chat bubble in the capture conversation (rep right, Rex left).
class ConversationBubble extends StatelessWidget {
  const ConversationBubble({super.key, required this.message});

  final ConversationMessage message;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.role == ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (!isUser) const _RexAvatar(),
          if (!isUser) const SizedBox(width: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.72,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSpacing.radiusMd),
                  topRight: const Radius.circular(AppSpacing.radiusMd),
                  bottomLeft: Radius.circular(isUser ? AppSpacing.radiusMd : 4),
                  bottomRight: Radius.circular(isUser ? 4 : AppSpacing.radiusMd),
                ),
                border: isUser ? null : Border.all(color: AppColors.cardBorder),
              ),
              child: message.pending
                  ? const TypingDots()
                  : Text(
                      message.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : AppColors.ink,
                        height: 1.4,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.12, curve: Curves.easeOut);
  }
}

class _RexAvatar extends StatelessWidget {
  const _RexAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.logoGradient),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Text('🦖', style: TextStyle(fontSize: 15)),
    );
  }
}
