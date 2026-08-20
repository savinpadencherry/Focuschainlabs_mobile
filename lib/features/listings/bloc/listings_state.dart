part of 'listings_bloc.dart';

enum ListingsStatus { initial, loading, refreshing, ready, failed }

class ListingsState extends Equatable {
  const ListingsState({
    this.status = ListingsStatus.initial,
    this.results = ListingResults.empty,
    this.filters = const ListingFilters(),
    this.sharing = false,
    this.shareReceipt = 0,
    this.error = '',
  });

  final ListingsStatus status;
  final ListingResults results;
  final ListingFilters filters;
  final bool sharing;

  /// How many (property, lead) rows the last share wrote. Drives the receipt.
  final int shareReceipt;
  final String error;

  bool get isLoading => status == ListingsStatus.loading;

  /// No results *and* no filters — the org genuinely has no inventory, which is
  /// a different message from "nothing matched this search".
  bool get inventoryIsEmpty => results.total == 0 && filters.isEmpty;

  /// The active constraints, as (field, label) pairs for removable chips.
  List<(String, String)> get activeChips => <(String, String)>[
        if (filters.query.isNotEmpty) ('query', '"${filters.query}"'),
        if (filters.bhk.isNotEmpty) ('bhk', filters.bhk),
        if (filters.propertyType.isNotEmpty) ('property_type', filters.propertyType),
        if (filters.locality.isNotEmpty) ('locality', filters.locality),
        if (filters.status.isNotEmpty) ('status', filters.status),
        // One formatter for the whole app: this one printed "₹1.20 Cr" while
        // the card beside it printed "₹1.2 Cr" for the same number.
        if (filters.maxPrice > 0)
          ('max_price', 'under ${Inr.format(filters.maxPrice)}'),
        if (filters.minPrice > 0)
          ('min_price', 'above ${Inr.format(filters.minPrice)}'),
      ];

  ListingsState copyWith({
    ListingsStatus? status,
    ListingResults? results,
    ListingFilters? filters,
    bool? sharing,
    int? shareReceipt,
    String? error,
  }) =>
      ListingsState(
        status: status ?? this.status,
        results: results ?? this.results,
        filters: filters ?? this.filters,
        sharing: sharing ?? this.sharing,
        shareReceipt: shareReceipt ?? this.shareReceipt,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props =>
      <Object?>[status, results, filters, sharing, shareReceipt, error];
}
