import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/models/extraction.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/mono_label.dart';
import '../../../../shared/widgets/sentiment_chip.dart';

/// The "ready to save" card Rex shows once it has gathered enough — a glance at
/// what will be written, with one tap to save (create or update the record).
class ExtractionSummaryCard extends StatelessWidget {
  const ExtractionSummaryCard({
    super.key,
    required this.extraction,
    required this.onSave,
    this.saving = false,
  });

  final Extraction extraction;
  final VoidCallback onSave;
  final bool saving;

  bool get _isTask => extraction.routesToTrello;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: -10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MonoLabel(_isTask ? 'Ready · Trello task' : 'Ready · CRM record'),
          AppSpacing.vGapMd,
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  extraction.client,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
              SentimentChip(sentiment: extraction.sentiment, compact: true),
            ],
          ),
          AppSpacing.vGapSm,
          Text(extraction.summary,
              style: const TextStyle(color: AppColors.inkSoft, height: 1.4)),
          if (extraction.dealStageChange != null)
            _row(Icons.trending_up_rounded, 'Stage → ${extraction.dealStageChange}'),
          if (extraction.followUpDate != null)
            _row(Icons.event_available_outlined,
                'Follow-up ${Formatters.dayShort(extraction.followUpDate!)}'),
          for (final ActionItem a in extraction.actionItems)
            _row(Icons.check_circle_outline_rounded, a.title),
          AppSpacing.vGapLg,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(saving
                  ? 'Saving…'
                  : (_isTask ? 'Save & update Trello' : 'Save to CRM')),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.1, curve: Curves.easeOut);
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 16, color: AppColors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
          ],
        ),
      );
}
