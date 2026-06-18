import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/extraction.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../bloc/capture_flow_bloc.dart';
import 'extraction_fields.dart';

/// The "one glance" review (F2/F4): the structured record shown for a quick
/// check with inline edits, then a single Confirm that writes everything.
class ReviewPanel extends StatelessWidget {
  const ReviewPanel({super.key, required this.state});

  final CaptureFlowState state;

  @override
  Widget build(BuildContext context) {
    final Extraction? extraction = state.extraction;
    if (extraction == null) return const SizedBox.shrink();
    final CaptureFlowBloc bloc = context.read<CaptureFlowBloc>();

    void update(Extraction next) =>
        bloc.add(CaptureExtractionChanged(next));

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: <Widget>[
              if (state.transcript != null)
                TranscriptCard(transcript: state.transcript!),
              AppSpacing.vGapLg,
              DestinationField(
                value: extraction.destination,
                onChanged: (String d) => update(extraction.copyWith(destination: d)),
              ),
              AppSpacing.vGapLg,
              ClientHeaderField(
                extraction: extraction,
                onChanged: (String v) => update(extraction.copyWith(client: v)),
              ),
              AppSpacing.vGapLg,
              UpdateTypeField(
                value: extraction.updateType,
                onChanged: (t) => update(extraction.copyWith(updateType: t)),
              ),
              AppSpacing.vGapLg,
              SummaryField(
                value: extraction.summary,
                onChanged: (String v) => update(extraction.copyWith(summary: v)),
              ),
              AppSpacing.vGapLg,
              SentimentField(
                value: extraction.sentiment,
                onChanged: (s) => update(extraction.copyWith(sentiment: s)),
              ),
              if (extraction.dealStageChange != null) ...<Widget>[
                AppSpacing.vGapLg,
                StageChangeField(stage: extraction.dealStageChange!),
              ],
              if (extraction.actionItems.isNotEmpty) ...<Widget>[
                AppSpacing.vGapLg,
                ActionItemsField(
                  items: extraction.actionItems,
                  onToggle: (int i) =>
                      bloc.add(CaptureActionItemToggled(i)),
                ),
              ],
              if (extraction.followUpDate != null) ...<Widget>[
                AppSpacing.vGapLg,
                FollowUpField(date: extraction.followUpDate!),
              ],
              AppSpacing.vGapLg,
              WritePreviewCard(extraction: extraction),
              if (state.message != null) ...<Widget>[
                AppSpacing.vGapSm,
                Text(
                  state.message!,
                  style: const TextStyle(color: AppColors.negative, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        _ConfirmBar(
          canWrite: extraction.isValid,
          destination: extraction.destination,
        ),
      ],
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({required this.canWrite, required this.destination});

  final bool canWrite;
  final String destination;

  @override
  Widget build(BuildContext context) {
    final String label = destination == 'trello'
        ? 'Confirm & create task'
        : 'Confirm & write to CRM';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: () =>
                  context.read<CaptureFlowBloc>().add(const CaptureReset()),
              child: const Text('Redo'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: canWrite
                  ? () => context
                      .read<CaptureFlowBloc>()
                      .add(const CaptureConfirmed())
                  : null,
              icon: const Icon(Icons.check_rounded),
              label: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}
