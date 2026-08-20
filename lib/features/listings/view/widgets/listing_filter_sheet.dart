import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/listing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/inr.dart';
import '../../bloc/listings_bloc.dart';

/// The search filters, budget first.
///
/// Every one of these constraints was already in [ListingFilters], in the
/// bloc, and in the API — and none of them could be *set*. The only control on
/// the surface was the text field, so a rep looking for a 3 BHK under ₹2 Cr in
/// Whitefield had to hope the words happened to appear in a description. The
/// chips that restate a search were built to be removed and there was no way
/// to add one.
///
/// Budget is two typed fields rather than a slider. Inventory here spans
/// ₹35 lakh to ₹12 crore, and a slider over that range moves in ₹20 lakh steps
/// under a thumb — useless for "under 2 Cr, and I mean 2". The presets cover
/// the common asks in one tap; the fields take "1.2 Cr", "80 L" or a plain
/// number, which is how the price is written everywhere else in the CRM.
class ListingFilterSheet extends StatefulWidget {
  const ListingFilterSheet({super.key, required this.filters});

  final ListingFilters filters;

  static Future<void> open(BuildContext context, ListingFilters filters) {
    final ListingsBloc bloc = context.read<ListingsBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider<ListingsBloc>.value(
        value: bloc,
        child: ListingFilterSheet(filters: filters),
      ),
    );
  }

  @override
  State<ListingFilterSheet> createState() => _ListingFilterSheetState();
}

class _ListingFilterSheetState extends State<ListingFilterSheet> {
  late final TextEditingController _min =
      TextEditingController(text: Inr.format(widget.filters.minPrice));
  late final TextEditingController _max =
      TextEditingController(text: Inr.format(widget.filters.maxPrice));
  late final TextEditingController _locality =
      TextEditingController(text: widget.filters.locality);

  late String _bhk = widget.filters.bhk;
  late String _propertyType = widget.filters.propertyType;
  late String _status = widget.filters.status;

  /// The budgets people actually ask for, as (label, min, max).
  static const List<(String, double, double)> _presets =
      <(String, double, double)>[
    ('Under ₹50 L', 0, 50 * Inr.lakh),
    ('₹50 L – 1 Cr', 50 * Inr.lakh, Inr.crore),
    ('₹1 – 2 Cr', Inr.crore, 2 * Inr.crore),
    ('₹2 – 5 Cr', 2 * Inr.crore, 5 * Inr.crore),
    ('₹5 Cr +', 5 * Inr.crore, 0),
  ];

  static const List<String> _bhks = <String>['1 BHK', '2 BHK', '3 BHK', '4 BHK', '5 BHK'];
  static const List<String> _types = <String>[
    'Apartment',
    'Villa',
    'Independent House',
    'Plot',
    'Commercial',
  ];
  static const List<String> _statuses = <String>['available', 'on hold', 'sold'];

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    _locality.dispose();
    super.dispose();
  }

  double get _minValue => Inr.parse(_min.text);
  double get _maxValue => Inr.parse(_max.text);

  /// Whether the range is the wrong way round. Sent as typed it would match
  /// nothing at all, with no clue why.
  bool get _inverted =>
      _minValue > 0 && _maxValue > 0 && _minValue > _maxValue;

  void _applyPreset(double min, double max) {
    setState(() {
      _min.text = Inr.format(min);
      _max.text = Inr.format(max);
    });
  }

  void _apply() {
    if (_inverted) return;
    context.read<ListingsBloc>().add(
          ListingsFiltered(
            widget.filters.copyWith(
              minPrice: _minValue,
              maxPrice: _maxValue,
              bhk: _bhk,
              propertyType: _propertyType,
              status: _status,
              locality: _locality.text.trim(),
            ),
          ),
        );
    Navigator.pop(context);
  }

  void _clear() {
    context.read<ListingsBloc>().add(
          // The query stays: it is what the user typed in the field behind
          // this sheet, and clearing it from here would look like the sheet
          // ate their search.
          ListingsFiltered(ListingFilters(query: widget.filters.query)),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController controller) => Column(
        children: <Widget>[
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorderStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Narrow the search',
                        style: text.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(onPressed: _clear, child: const Text('Clear all')),
                  ],
                ),
                AppSpacing.vGapLg,
                Text('Budget', style: text.labelLarge),
                AppSpacing.vGapSm,
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final (String label, double min, double max) in _presets)
                      _Choice(
                        label: label,
                        selected: _minValue == min && _maxValue == max,
                        onTap: () => _applyPreset(min, max),
                      ),
                  ],
                ),
                AppSpacing.vGapMd,
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _Amount(
                        controller: _min,
                        label: 'From',
                        onChanged: () => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Amount(
                        controller: _max,
                        label: 'Up to',
                        onChanged: () => setState(() {}),
                      ),
                    ),
                  ],
                ),
                if (_inverted) ...<Widget>[
                  AppSpacing.vGapSm,
                  Text(
                    'The lower figure is above the upper one — nothing can match that.',
                    style: text.bodySmall?.copyWith(color: AppColors.negative),
                  ),
                ] else if (_minValue > 0 || _maxValue > 0) ...<Widget>[
                  AppSpacing.vGapSm,
                  Text(_budgetSentence, style: text.bodySmall),
                ],
                AppSpacing.vGapLg,
                Text('Configuration', style: text.labelLarge),
                AppSpacing.vGapSm,
                _ChoiceRow(
                  options: _bhks,
                  selected: _bhk,
                  onChanged: (String v) => setState(() => _bhk = v),
                ),
                AppSpacing.vGapLg,
                Text('Property type', style: text.labelLarge),
                AppSpacing.vGapSm,
                _ChoiceRow(
                  options: _types,
                  selected: _propertyType,
                  onChanged: (String v) => setState(() => _propertyType = v),
                ),
                AppSpacing.vGapLg,
                Text('Status', style: text.labelLarge),
                AppSpacing.vGapSm,
                _ChoiceRow(
                  options: _statuses,
                  selected: _status,
                  onChanged: (String v) => setState(() => _status = v),
                ),
                AppSpacing.vGapLg,
                TextField(
                  controller: _locality,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Area or city',
                    hintText: 'Whitefield',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                AppSpacing.vGapXl,
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              12 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _inverted ? null : _apply,
                child: const Text('Show properties'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The filter restated in words, so the parse is visible before it runs.
  /// "1.2cr" typed into a box is only obviously ₹1.2 Cr once something says so.
  String get _budgetSentence {
    if (_minValue > 0 && _maxValue > 0) {
      return 'Between ${Inr.format(_minValue)} and ${Inr.format(_maxValue)}';
    }
    if (_maxValue > 0) return 'Up to ${Inr.format(_maxValue)}';
    return '${Inr.format(_minValue)} and above';
  }
}

/// A budget box. Free text on purpose — "1.2 Cr" is how the price is written
/// on the listing, in the lead's record and in the message sent to a client.
class _Amount extends StatelessWidget {
  const _Amount({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        hintText: '1.2 Cr',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

/// A row of single-choice chips. Tapping the selected one clears it, so every
/// constraint can be dropped without hunting for an "any" option.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (final String option in options)
          _Choice(
            label: option,
            selected: selected.toLowerCase() == option.toLowerCase(),
            onTap: () => onChanged(
              selected.toLowerCase() == option.toLowerCase() ? '' : option,
            ),
          ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.iris : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: selected ? AppColors.iris : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}
