part of 'lookup_bloc.dart';

sealed class LookupEvent extends Equatable {
  const LookupEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class LookupAsked extends LookupEvent {
  const LookupAsked(this.query);

  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

final class LookupCleared extends LookupEvent {
  const LookupCleared();
}
