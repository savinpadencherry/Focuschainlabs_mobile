part of 'ona_bloc.dart';

enum OnaStatus { initial, loading, ready }

class OnaState extends Equatable {
  const OnaState({
    this.status = OnaStatus.initial,
    this.turns = const <OnaTurn>[],
    this.busy = false,
    this.pendingPlan,
    this.error = '',
  });

  final OnaStatus status;
  final List<OnaTurn> turns;
  final bool busy;

  /// The plan Ona is waiting on the user about. Travels back to the server
  /// with their answer, because the server keeps no session.
  final Map<String, dynamic>? pendingPlan;
  final String error;

  bool get isEmpty => turns.isEmpty;

  /// True when the last turn is asking the user to approve or decline.
  bool get awaitingDecision =>
      pendingPlan != null && turns.isNotEmpty && !busy;

  OnaState copyWith({
    OnaStatus? status,
    List<OnaTurn>? turns,
    bool? busy,
    Map<String, dynamic>? pendingPlan,
    bool clearPendingPlan = false,
    String? error,
  }) =>
      OnaState(
        status: status ?? this.status,
        turns: turns ?? this.turns,
        busy: busy ?? this.busy,
        pendingPlan: clearPendingPlan ? null : (pendingPlan ?? this.pendingPlan),
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => <Object?>[status, turns, busy, pendingPlan, error];
}
