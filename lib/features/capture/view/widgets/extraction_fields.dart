import 'package:flutter/material.dart';

import '../../../../core/models/enums.dart';
import '../../../../core/models/extraction.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';

/// Labelled container for one review field.
class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.label, required this.child, this.icon});

  final String label;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 6),
            ],
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        child,
      ],
    );
  }
}

/// Read-only card showing the raw transcript the extraction came from.
class TranscriptCard extends StatelessWidget {
  const TranscriptCard({super.key, required this.transcript});

  final String transcript;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.graphic_eq_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'YOU SAID',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('“$transcript”', style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }
}

class ClientHeaderField extends StatefulWidget {
  const ClientHeaderField({
    super.key,
    required this.extraction,
    required this.onChanged,
  });

  final Extraction extraction;
  final ValueChanged<String> onChanged;

  @override
  State<ClientHeaderField> createState() => _ClientHeaderFieldState();
}

class _ClientHeaderFieldState extends State<ClientHeaderField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.extraction.client);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool unknown = widget.extraction.client == 'Unknown client';
    return _FieldShell(
      label: 'Client',
      icon: Icons.business_rounded,
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: unknown
              ? const Tooltip(
                  message: 'Which client? Please confirm.',
                  child: Icon(Icons.help_outline_rounded, color: AppColors.atRisk),
                )
              : const Icon(Icons.edit_outlined, size: 18),
        ),
      ),
    );
  }
}

class SummaryField extends StatefulWidget {
  const SummaryField({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<SummaryField> createState() => _SummaryFieldState();
}

class _SummaryFieldState extends State<SummaryField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: 'Summary',
      icon: Icons.notes_rounded,
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        maxLines: null,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class UpdateTypeField extends StatelessWidget {
  const UpdateTypeField({super.key, required this.value, required this.onChanged});

  final UpdateType value;
  final ValueChanged<UpdateType> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: 'Update type',
      icon: Icons.category_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: UpdateType.values.map((UpdateType t) {
          final bool selected = t == value;
          return ChoiceChip(
            label: Text(t.label),
            selected: selected,
            onSelected: (_) => onChanged(t),
            showCheckmark: false,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
            backgroundColor: AppColors.surfaceMuted,
          );
        }).toList(),
      ),
    );
  }
}

class SentimentField extends StatelessWidget {
  const SentimentField({super.key, required this.value, required this.onChanged});

  final Sentiment value;
  final ValueChanged<Sentiment> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: 'Sentiment',
      icon: Icons.mood_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: Sentiment.values.map((Sentiment s) {
          final bool selected = s == value;
          final Color color = AppColors.sentiment(s.wire);
          return ChoiceChip(
            label: Text(s.label),
            selected: selected,
            onSelected: (_) => onChanged(s),
            showCheckmark: false,
            selectedColor: color,
            labelStyle: TextStyle(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
            backgroundColor: color.withValues(alpha: 0.12),
          );
        }).toList(),
      ),
    );
  }
}

class StageChangeField extends StatelessWidget {
  const StageChangeField({super.key, required this.stage});

  final String stage;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: 'Deal stage change',
      icon: Icons.trending_up_rounded,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.positive.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.arrow_forward_rounded,
                size: 16, color: AppColors.positive),
            const SizedBox(width: 8),
            Text(
              'Move to “$stage”',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.positive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionItemsField extends StatelessWidget {
  const ActionItemsField({super.key, required this.items, required this.onToggle});

  final List<ActionItem> items;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: 'Action items → task tool',
      icon: Icons.checklist_rounded,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < items.length; i++)
            _ActionRow(item: items[i], onToggle: () => onToggle(i)),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.item, required this.onToggle});

  final ActionItem item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            Icon(
              item.selected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: item.selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: item.selected ? null : TextDecoration.lineThrough,
                      color: item.selected
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                  if (item.due != null)
                    Text(
                      'Due ${Formatters.dayShort(item.due!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
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

class DestinationField extends StatelessWidget {
  const DestinationField({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: 'Destination (you can override Rex)',
      icon: Icons.alt_route_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          _DestinationChip(
            label: 'CRM update',
            subtitle: 'Log to leads / contacts',
            icon: Icons.people_alt_outlined,
            selected: value == 'crm',
            onTap: () => onChanged('crm'),
          ),
          _DestinationChip(
            label: 'Trello task',
            subtitle: 'Create board card(s)',
            icon: Icons.view_kanban_outlined,
            selected: value == 'trello',
            onTap: () => onChanged('trello'),
          ),
        ],
      ),
    );
  }
}

class _DestinationChip extends StatelessWidget {
  const _DestinationChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: selected ? AppColors.primary : AppColors.textMuted, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows exactly what will be written on confirm.
class WritePreviewCard extends StatelessWidget {
  const WritePreviewCard({super.key, required this.extraction});

  final Extraction extraction;

  @override
  Widget build(BuildContext context) {
    final bool hasClient = extraction.client.trim().isNotEmpty &&
        extraction.client.toLowerCase() != 'unknown client';
    final bool hasTasks =
        extraction.actionItems.any((ActionItem a) => a.selected);
    final bool writeCrm =
        extraction.destination == 'crm' || hasTasks || hasClient;
    final bool writeTrello = extraction.routesToTrello ||
        hasTasks ||
        extraction.updateType == UpdateType.followUp;

    return _FieldShell(
      label: 'Will write',
      icon: Icons.output_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (writeCrm)
            _PreviewRow(
              icon: Icons.cloud_upload_outlined,
              title: 'GitHub CRM',
              body: 'Contact: ${extraction.client}\n'
                  'Status: ${extraction.dealStageChange ?? 'unchanged'}\n'
                  'Sentiment: ${extraction.sentiment.label}\n'
                  'Note: ${extraction.summary}',
            ),
          if (writeCrm && writeTrello) AppSpacing.vGapSm,
          if (writeTrello)
            _PreviewRow(
              icon: Icons.view_kanban_outlined,
              title: 'Trello',
              body: hasTasks
                  ? extraction.actionItems
                      .where((ActionItem a) => a.selected)
                      .map((ActionItem a) =>
                          '• ${a.title}${a.due != null ? ' (due ${Formatters.dayShort(a.due!)})' : ''}')
                      .join('\n')
                  : '• ${extraction.summary}'
                      '${extraction.followUpDate != null ? ' (due ${Formatters.dayShort(extraction.followUpDate!)})' : ''}',
            ),
          if (!writeCrm && !writeTrello)
            const Text('Nothing to write — check destination and fields.'),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(height: 1.4, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FollowUpField extends StatelessWidget {
  const FollowUpField({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: 'Follow-up → calendar',
      icon: Icons.event_available_outlined,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.calendar_today_rounded,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              Formatters.day(date),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
