part of 'listings_bloc.dart';

sealed class ListingsEvent extends Equatable {
  const ListingsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class ListingsLoaded extends ListingsEvent {
  const ListingsLoaded();
}

/// Stand down: this tenant has no Listings surface, so there is nothing to
/// fetch. The bloc still exists because Ona can answer a property question for
/// any tenant that has inventory on file, and its cards need somewhere to
/// record a share.
class ListingsIdle extends ListingsEvent {
  const ListingsIdle();
}

class ListingsFiltered extends ListingsEvent {
  const ListingsFiltered(this.filters);

  final ListingFilters filters;

  @override
  List<Object?> get props => <Object?>[filters];
}

/// Drop one constraint by name ('bhk', 'locality', 'max_price', …).
class ListingsFilterCleared extends ListingsEvent {
  const ListingsFilterCleared(this.field);

  final String field;

  @override
  List<Object?> get props => <Object?>[field];
}

class ListingsShared extends ListingsEvent {
  const ListingsShared({
    required this.listingIds,
    required this.contactId,
    required this.channel,
  });

  final List<String> listingIds;
  final String contactId;
  final String channel;

  @override
  List<Object?> get props => <Object?>[listingIds, contactId, channel];
}
