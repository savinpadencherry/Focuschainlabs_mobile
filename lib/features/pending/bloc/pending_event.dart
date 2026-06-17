part of 'pending_bloc.dart';

sealed class PendingEvent extends Equatable {
  const PendingEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class PendingRequested extends PendingEvent {
  const PendingRequested();
}
