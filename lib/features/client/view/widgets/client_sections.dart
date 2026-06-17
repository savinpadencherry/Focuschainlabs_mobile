import 'package:flutter/material.dart';

import '../../../../core/models/client.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/sentiment_chip.dart';

/// Reusable titled container for a client-detail section.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.vGapMd,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: child,
        ),
      ],
    );
  }
}

class DealsSection extends StatelessWidget {
  const DealsSection({super.key, required this.deals});

  final List<Deal> deals;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Open deals',
      child: Column(
        children: <Widget>[
          for (int i = 0; i < deals.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        deals[i].title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deals[i].stage.label,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      deals[i].value,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    SentimentChip(sentiment: deals[i].sentiment, compact: true),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class FollowUpsSection extends StatelessWidget {
  const FollowUpsSection({super.key, required this.followUps});

  final List<String> followUps;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Pending follow-ups',
      child: Column(
        children: followUps
            .map((String f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.flag_outlined,
                          size: 18, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Expanded(child: Text(f)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class ContactsSection extends StatelessWidget {
  const ContactsSection({super.key, required this.contacts});

  final List<Contact> contacts;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Key contacts',
      child: Column(
        children: <Widget>[
          for (int i = 0; i < contacts.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 18),
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceMuted,
                  child: Text(
                    contacts[i].name.substring(0, 1),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        contacts[i].name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        contacts[i].title,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class TimelineSection extends StatelessWidget {
  const TimelineSection({super.key, required this.interactions});

  final List<Interaction> interactions;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Recent interactions',
      child: Column(
        children: <Widget>[
          for (int i = 0; i < interactions.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i != interactions.length - 1)
                      Container(
                        width: 2,
                        height: 36,
                        color: AppColors.cardBorder,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(interactions[i].summary),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.relative(interactions[i].date),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class EmailsSection extends StatelessWidget {
  const EmailsSection({super.key, required this.subjects});

  final List<String> subjects;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Recent emails (read-only)',
      child: Column(
        children: subjects
            .map((String s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.mail_outline_rounded,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
