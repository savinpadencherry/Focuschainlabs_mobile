import 'package:flutter/material.dart';

import '../../../../core/get.dart';
import '../../../../core/models/activity.dart';
import '../../../../core/models/crm.dart';
import '../../../../core/repository/capture_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/web_view_screen.dart';

/// After a write, routes the rep to the right place (per the product flow):
/// a CRM update shows the contact's interaction history + opens the CRM in
/// desktop view; a task opens the Trello board.
class CaptureResultActions extends StatelessWidget {
  const CaptureResultActions({super.key, required this.entry});

  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    if (entry.isTask) {
      return _TaskResult(entry: entry);
    }
    return _CrmResult(entry: entry);
  }
}

class _TaskResult extends StatelessWidget {
  const _TaskResult({required this.entry});

  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    if (!entry.canOpenTrello) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => WebViewScreen.open(
          context,
          url: entry.trelloUrl!,
          title: 'Trello board',
        ),
        icon: const Icon(Icons.view_kanban_outlined),
        label: const Text('Open Trello board'),
      ),
    );
  }
}

class _CrmResult extends StatelessWidget {
  const _CrmResult({required this.entry});

  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HistoryList(contactRef: entry.contactId ?? entry.clientName),
        AppSpacing.vGapLg,
        if (entry.canOpenCrm)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => WebViewScreen.open(
                context,
                url: entry.crmWebUrl!,
                title: '${entry.clientName} · CRM',
                desktopView: true,
              ),
              icon: const Icon(Icons.open_in_full_rounded),
              label: const Text('Open CRM (desktop view)'),
            ),
          ),
      ],
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.contactRef});

  final String contactRef;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CrmInteraction>>(
      future: app<CaptureRepository>().historyFor(contactRef),
      builder: (BuildContext context, AsyncSnapshot<List<CrmInteraction>> snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final List<CrmInteraction> items = snap.data ?? <CrmInteraction>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Interaction history',
                style: Theme.of(context).textTheme.titleMedium),
            AppSpacing.vGapMd,
            ...items.take(4).map((CrmInteraction i) => _HistoryTile(item: i)),
          ],
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});

  final CrmInteraction item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            item.kind == 'email'
                ? Icons.mail_outline_rounded
                : Icons.chat_bubble_outline_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.body, style: const TextStyle(fontSize: 13.5, height: 1.35)),
                const SizedBox(height: 2),
                Text(
                  '${item.author.isEmpty ? '' : '${item.author} · '}'
                  '${Formatters.relative(item.createdAt)}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
