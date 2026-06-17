part of 'pending_bloc.dart';

enum PendingStatus { initial, loading, ready, failure }

class PendingState extends Equatable {
  const PendingState({
    this.status = PendingStatus.initial,
    this.captures = const <Capture>[],
    this.message,
  });

  final PendingStatus status;
  final List<Capture> captures;
  final String? message;

  PendingState copyWith({
    PendingStatus? status,
    List<Capture>? captures,
    String? message,
  }) =>
      PendingState(
        status: status ?? this.status,
        captures: captures ?? this.captures,
        message: message ?? this.message,
      );

  @override
  List<Object?> get props => <Object?>[status, captures, message];
}
