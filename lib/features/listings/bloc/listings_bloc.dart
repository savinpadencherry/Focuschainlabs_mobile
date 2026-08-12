import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/get.dart';
import '../../../core/models/listing.dart';
import '../../../core/repository/crm_repository.dart';
import '../../../core/services/api/secona_api.dart';
import '../../../core/services/firebase/analytics_service.dart';

part 'listings_event.dart';
part 'listings_state.dart';

/// Inventory search.
class ListingsBloc extends Bloc<ListingsEvent, ListingsState> {
  ListingsBloc({required CrmRepository repository})
      : _repository = repository,
        super(const ListingsState()) {
    on<ListingsLoaded>(_onLoaded);
    on<ListingsIdle>(_onIdle);
    on<ListingsFiltered>(_onFiltered);
    on<ListingsFilterCleared>(_onFilterCleared);
    on<ListingsShared>(_onShared);
  }

  final CrmRepository _repository;

  Future<void> _onLoaded(ListingsLoaded event, Emitter<ListingsState> emit) async {
    emit(state.copyWith(
      status: state.results.listings.isEmpty
          ? ListingsStatus.loading
          : ListingsStatus.refreshing,
      error: '',
    ));
    try {
      final ListingResults results = await _repository.listings(state.filters);
      emit(state.copyWith(status: ListingsStatus.ready, results: results));
    } on ApiException catch (e) {
      emit(state.copyWith(status: ListingsStatus.failed, error: e.message));
    }
  }

  void _onIdle(ListingsIdle event, Emitter<ListingsState> emit) {
    emit(state.copyWith(status: ListingsStatus.ready));
  }

  Future<void> _onFiltered(
    ListingsFiltered event,
    Emitter<ListingsState> emit,
  ) async {
    emit(state.copyWith(filters: event.filters));
    // Which constraints are used, never their values.
    app<AnalyticsService>().log(
      AnalyticsEvents.listingsSearched,
      <String, Object>{
        'has_query': event.filters.query.isNotEmpty,
        'has_bhk': event.filters.bhk.isNotEmpty,
        'has_locality': event.filters.locality.isNotEmpty,
        'has_budget': event.filters.maxPrice > 0 || event.filters.minPrice > 0,
      },
    );
    add(const ListingsLoaded());
  }

  /// Drop exactly one constraint.
  ///
  /// An empty search should name what it searched for and offer to widen, one
  /// chip per constraint — "no 3 BHK in Whitefield under ₹4 Cr" with a way to
  /// drop each part beats "Nothing to show".
  void _onFilterCleared(
    ListingsFilterCleared event,
    Emitter<ListingsState> emit,
  ) {
    final ListingFilters f = state.filters;
    final ListingFilters next = switch (event.field) {
      'query' => f.copyWith(query: ''),
      'locality' => f.copyWith(locality: ''),
      'property_type' => f.copyWith(propertyType: ''),
      'bhk' => f.copyWith(bhk: ''),
      'status' => f.copyWith(status: ''),
      'min_price' => f.copyWith(minPrice: 0),
      'max_price' => f.copyWith(maxPrice: 0),
      _ => const ListingFilters(),
    };
    add(ListingsFiltered(next));
  }

  Future<void> _onShared(ListingsShared event, Emitter<ListingsState> emit) async {
    emit(state.copyWith(sharing: true, error: '', shareReceipt: 0));
    try {
      final int recorded = await _repository.recordShare(
        listingIds: event.listingIds,
        contactId: event.contactId,
        channel: event.channel,
      );
      emit(state.copyWith(sharing: false, shareReceipt: recorded));
      app<AnalyticsService>().log(
        AnalyticsEvents.listingShared,
        <String, Object>{'count': event.listingIds.length, 'channel': event.channel},
      );
      // Share counts are on the cards, so the list is now one write out of date.
      add(const ListingsLoaded());
    } on ApiException catch (e) {
      emit(state.copyWith(sharing: false, error: e.message));
    }
  }
}
