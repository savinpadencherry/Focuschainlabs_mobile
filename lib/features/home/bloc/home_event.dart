part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Load (or refresh) the home dashboard.
final class HomeLoaded extends HomeEvent {
  const HomeLoaded();
}
