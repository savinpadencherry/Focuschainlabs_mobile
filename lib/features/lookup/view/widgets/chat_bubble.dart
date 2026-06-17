import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/models/lookup.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'citations_row.dart';
import 'client_360_card.dart';
import 'typing_dots.dart';

/// One bubble in the lookup thread. User messages sit right and tinted; Rex's
/// answers sit left with optional grounding citations and a client-360 card.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.role == ChatRole.user;
    final Alignment align = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width > 600 ? 520 : 320,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
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
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        height: 1.45,
                        fontSize: 15,
                      ),
                    ),
            ),
            if (message.answer?.isClient360 ?? false) ...<Widget>[
              AppSpacing.vGapSm,
              Client360Card(clientId: message.answer!.clientId!),
            ],
            if ((message.answer?.citations.isNotEmpty ?? false)) ...<Widget>[
              AppSpacing.vGapSm,
              CitationsRow(citations: message.answer!.citations),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(
          begin: 0.15,
          curve: Curves.easeOut,
        );
  }
}
