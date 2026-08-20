import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/get.dart';
import '../../../../core/models/pipeline.dart';
import '../../../../core/repository/crm_repository.dart';
import '../../../../core/services/api/identity_cache.dart';
import '../../../../core/services/api/secona_api.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../bloc/pipeline_bloc.dart';

/// Edit a lead's details.
///
/// Only the fields the API allows, and only the ones worth correcting from a
/// phone. `owner` and the tenant are deliberately absent — those are not edits,
/// they are reassignments, and the server refuses them from a request body for
/// the same reason.
///
/// The form is filtered against the server's own allowlist, which `/api/me`
/// publishes. A field this server will not take is not shown at all, rather
/// than offered and then rejected with "Fields not editable here" after the
/// user has typed into it.
///
/// Saves through the audited write gateway, so the change is on the web app
/// immediately and in the audit log with the editor's name against it.
class LeadEditSheet extends StatefulWidget {
  const LeadEditSheet({super.key, required this.lead});

  final Lead lead;

  /// Returns the stored lead when something was saved.
  static Future<Lead?> open(BuildContext context, Lead lead) {
    final PipelineBloc bloc = context.read<PipelineBloc>();
    return showModalBottomSheet<Lead>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider<PipelineBloc>.value(
        value: bloc,
        child: LeadEditSheet(lead: lead),
      ),
    );
  }

  @override
  State<LeadEditSheet> createState() => _LeadEditSheetState();
}

class _LeadEditSheetState extends State<LeadEditSheet> {
  late final Map<String, TextEditingController> _fields =
      <String, TextEditingController>{
    'name': TextEditingController(text: widget.lead.name),
    'company': TextEditingController(text: widget.lead.company),
    'phone': TextEditingController(text: widget.lead.phone),
    'email': TextEditingController(text: widget.lead.email),
    'budget': TextEditingController(text: widget.lead.budget),
    'locality': TextEditingController(text: widget.lead.locality),
    'requirement': TextEditingController(text: widget.lead.requirement),
    'bhk': TextEditingController(text: widget.lead.bhk),
    'property_type': TextEditingController(text: widget.lead.propertyType),
    'possession': TextEditingController(text: widget.lead.possession),
    'source': TextEditingController(text: widget.lead.source),
    'next_follow_up': TextEditingController(text: widget.lead.nextFollowUp),
    'notes': TextEditingController(
      text: widget.lead.notesArePrivate ? '' : widget.lead.notes,
    ),
  };

  static const Map<String, String> _labels = <String, String>{
    'name': 'Name',
    'company': 'Company',
    'phone': 'Phone',
    'email': 'Email',
    'budget': 'Budget',
    'locality': 'Locality',
    'requirement': 'Looking for',
    'bhk': 'Configuration',
    'property_type': 'Property type',
    'possession': 'Possession',
    'source': 'Source',
    'next_follow_up': 'Next follow-up',
    'notes': 'Notes',
  };

  /// The fields to show: the intersection of this form and the server's own
  /// allowlist. `/api/me` publishes that list, so a column added to it reaches
  /// installed phones without a release — and one removed from it stops being
  /// offered rather than being rejected after the fact.
  Iterable<String> get _offered =>
      _fields.keys.where(IdentityCache.access.canEditLeadField);

  bool _saving = false;
  String _error = '';

  @override
  void dispose() {
    for (final TextEditingController c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _original(String key) => switch (key) {
        'name' => widget.lead.name,
        'company' => widget.lead.company,
        'phone' => widget.lead.phone,
        'email' => widget.lead.email,
        'budget' => widget.lead.budget,
        'locality' => widget.lead.locality,
        'requirement' => widget.lead.requirement,
        'bhk' => widget.lead.bhk,
        'property_type' => widget.lead.propertyType,
        'possession' => widget.lead.possession,
        'source' => widget.lead.source,
        'next_follow_up' => widget.lead.nextFollowUp,
        'notes' => widget.lead.notesArePrivate ? '' : widget.lead.notes,
        _ => '',
      };

  Future<void> _save() async {
    final Map<String, dynamic> changes = <String, dynamic>{};
    for (final String key in _offered) {
      final TextEditingController c = _fields[key]!;
      final String now = c.text.trim();
      // Only what actually changed. Sending the whole form would put every
      // field in the audit log on every save, which makes the log useless for
      // answering "what did they change?".
      if (now != _original(key)) changes[key] = now;
    }

    if (changes.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      final Lead stored =
          await app<CrmRepository>().updateLead(widget.lead.id, changes);
      if (mounted) Navigator.pop(context, stored);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AppSpacing.vGapLg,
            Text(
              'Edit lead',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              widget.lead.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (widget.lead.notesArePrivate) ...<Widget>[
              AppSpacing.vGapSm,
              Text(
                'The notes on this lead belong to another rep, so they are not '
                'shown here. Anything you type will replace them.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.atRisk),
              ),
            ],
            AppSpacing.vGapLg,
            for (final String key in _offered) ...<Widget>[
              _Field(
                label: _labels[key] ?? key,
                controller: _fields[key]!,
                lines: key == 'notes' ? 4 : 1,
                hint: key == 'next_follow_up' ? 'YYYY-MM-DD' : null,
                keyboard: switch (key) {
                  'phone' => TextInputType.phone,
                  'email' => TextInputType.emailAddress,
                  _ => TextInputType.text,
                },
              ),
              AppSpacing.vGapMd,
            ],
            if (_error.isNotEmpty) ...<Widget>[
              Text(_error, style: const TextStyle(color: AppColors.negative)),
              AppSpacing.vGapMd,
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(
                  _saving ? 'Saving…' : 'Save — the web app sees it too',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.lines = 1,
    this.hint,
    this.keyboard = TextInputType.text,
  });

  final String label;
  final TextEditingController controller;
  final int lines;
  final String? hint;
  final TextInputType keyboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        AppSpacing.vGapSm,
        TextField(
          controller: controller,
          minLines: lines,
          maxLines: lines,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            filled: true,
            fillColor: AppColors.surface,
            border: _border(AppColors.cardBorder),
            enabledBorder: _border(AppColors.cardBorder),
            focusedBorder: _border(AppColors.iris),
          ),
        ),
      ],
    );
  }

  static OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: c),
      );
}
