part of 'pipeline_bloc.dart';

sealed class PipelineEvent extends Equatable {
  const PipelineEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// (Re)fetch the board.
class PipelineLoaded extends PipelineEvent {
  const PipelineLoaded();
}

class PipelineSearched extends PipelineEvent {
  const PipelineSearched(this.query);

  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

/// Show one stage, or all of them when [stage] is null.
class PipelineStageFiltered extends PipelineEvent {
  const PipelineStageFiltered(this.stage);

  final Stage? stage;

  @override
  List<Object?> get props => <Object?>[stage];
}

class PipelineLeadOpened extends PipelineEvent {
  const PipelineLeadOpened(this.id);

  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}

class PipelineLeadClosed extends PipelineEvent {
  const PipelineLeadClosed();
}

class PipelineStageChanged extends PipelineEvent {
  const PipelineStageChanged(this.id, this.stage);

  final String id;
  final Stage stage;

  @override
  List<Object?> get props => <Object?>[id, stage];
}

class PipelineNoteLogged extends PipelineEvent {
  const PipelineNoteLogged(this.id, this.note);

  final String id;
  final String note;

  @override
  List<Object?> get props => <Object?>[id, note];
}
