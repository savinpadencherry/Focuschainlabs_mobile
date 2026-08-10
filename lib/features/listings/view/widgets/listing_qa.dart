import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/get.dart';
import '../../../../core/models/listing.dart';
import '../../../../core/repository/crm_repository.dart';
import '../../../../core/services/api/secona_api.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/crm_chips.dart';

/// The questions a rep gets asked while standing in a property.
///
/// Every answer is computed in SQL first and the model is given only those
/// facts. That ordering matters: asked "how does this compare" with no data, a
/// language model will invent a comparison, and a rep repeating an invented
/// price to a client is the failure this is built to avoid.
class ListingQa extends StatefulWidget {
  const ListingQa({super.key, required this.listing});

  final Listing listing;

  @override
  State<ListingQa> createState() => _ListingQaState();
}

class _ListingQaState extends State<ListingQa> {
  List<ListingQuestion> _questions = const <ListingQuestion>[];
  String _asked = '';
  String _answer = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<ListingQuestion> qs =
          await app<CrmRepository>().listingQuestions(widget.listing.id);
      if (mounted) setState(() => _questions = qs);
    } catch (_) {
      // A property that cannot list its questions still shows everything else.
    }
  }

  Future<void> _ask(ListingQuestion q) async {
    setState(() {
      _busy = true;
      _asked = q.label;
      _answer = '';
    });
    try {
      final String a =
          await app<CrmRepository>().askAboutListing(widget.listing.id, q.id);
      if (mounted) setState(() => _answer = a);
    } on ApiException catch (e) {
      if (mounted) setState(() => _answer = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Most asked', style: Theme.of(context).textTheme.labelLarge),
        AppSpacing.vGapSm,
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final ListingQuestion q in _questions)
              TagChip(
                q.label,
                color: _asked == q.label ? AppColors.green : AppColors.navy,
                filled: _asked == q.label,
                onTap: _busy ? null : () => _ask(q),
              ),
          ],
        ),
        if (_asked.isNotEmpty) ...<Widget>[
          AppSpacing.vGapSm,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: _busy
                ? const Row(
                    children: <Widget>[
                      SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.green,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('Checking the records…'),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _asked,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(_answer, style: const TextStyle(height: 1.4)),
                    ],
                  ),
          ).animate().fadeIn(duration: 240.ms).slideY(begin: 0.1),
        ],
      ],
    );
  }
}

/// Edit the fields a rep actually corrects from a phone.
///
/// Deliberately not the whole record — twenty-eight fields on a phone is a
/// form nobody finishes. The rest stay on the web app, which is where a
/// property is created in the first place.
class ListingEditSheet extends StatefulWidget {
  const ListingEditSheet({super.key, required this.listing});

  final Listing listing;

  /// Returns the stored listing when something was saved.
  static Future<Listing?> open(BuildContext context, Listing listing) {
    return showModalBottomSheet<Listing>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ListingEditSheet(listing: listing),
    );
  }

  @override
  State<ListingEditSheet> createState() => _ListingEditSheetState();
}

class _ListingEditSheetState extends State<ListingEditSheet> {
  late final TextEditingController _price =
      TextEditingController(text: widget.listing.price);
  late final TextEditingController _description =
      TextEditingController(text: widget.listing.description);
  late final TextEditingController _locality =
      TextEditingController(text: widget.listing.locality);
  late String _status = widget.listing.status;

  bool _saving = false;
  String _error = '';

  static const List<String> _statuses = <String>[
    'available',
    'under_offer',
    'sold',
    'rented',
    'withdrawn',
  ];

  @override
  void dispose() {
    _price.dispose();
    _description.dispose();
    _locality.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final Map<String, dynamic> changes = <String, dynamic>{
      if (_price.text.trim() != widget.listing.price) 'price': _price.text.trim(),
      if (_description.text.trim() != widget.listing.description)
        'description': _description.text.trim(),
      if (_locality.text.trim() != widget.listing.locality)
        'locality': _locality.text.trim(),
      if (_status != widget.listing.status) 'status': _status,
    };
    if (changes.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      final Listing stored =
          await app<CrmRepository>().editListing(widget.listing.id, changes);
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
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
              'Edit property',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(widget.listing.title,
                style: Theme.of(context).textTheme.bodySmall),
            AppSpacing.vGapLg,
            _Field(
              label: 'Price',
              controller: _price,
              hint: 'e.g. 3.3 Cr',
            ),
            AppSpacing.vGapMd,
            _Field(label: 'Locality', controller: _locality),
            AppSpacing.vGapMd,
            Text('Status', style: Theme.of(context).textTheme.labelLarge),
            AppSpacing.vGapSm,
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final String s in _statuses)
                  TagChip(
                    s.replaceAll('_', ' '),
                    color: s == 'available' ? AppColors.green : AppColors.navy,
                    filled: _status == s,
                    onTap: () => setState(() => _status = s),
                  ),
              ],
            ),
            AppSpacing.vGapMd,
            _Field(
              label: 'Description',
              controller: _description,
              lines: 4,
            ),
            if (_error.isNotEmpty) ...<Widget>[
              AppSpacing.vGapMd,
              Text(_error, style: const TextStyle(color: AppColors.negative)),
            ],
            AppSpacing.vGapLg,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save — the web app sees it too'),
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
    this.hint,
    this.lines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int lines;

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
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
          ),
        ),
      ],
    );
  }
}
