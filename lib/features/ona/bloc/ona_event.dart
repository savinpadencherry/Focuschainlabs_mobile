part of 'ona_bloc.dart';

sealed class OnaEvent extends Equatable {
  const OnaEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Load the morning brief, once, when the surface first opens.
class OnaOpened extends OnaEvent {
  const OnaOpened();
}

/// A message from the user.
///
/// [fromChip] is true when the text came from a chip the product wrote rather
/// than something a person typed. The server treats the two differently and
/// the distinction cannot be recovered later.
class OnaAsked extends OnaEvent {
  const OnaAsked(this.query, {this.fromChip = false});

  final String query;
  final bool fromChip;

  @override
  List<Object?> get props => <Object?>[query, fromChip];
}

/// The user approved the held plan.
class OnaConfirmed extends OnaEvent {
  const OnaConfirmed();
}

/// The user rejected the held plan.
class OnaDeclined extends OnaEvent {
  const OnaDeclined();
}

/// The user approved a specific write, from a composer.
class OnaActionApproved extends OnaEvent {
  const OnaActionApproved(this.action, this.params);

  final String action;
  final Map<String, dynamic> params;

  @override
  List<Object?> get props => <Object?>[action, params];
}

/// Start a new thread.
class OnaCleared extends OnaEvent {
  const OnaCleared();
}
