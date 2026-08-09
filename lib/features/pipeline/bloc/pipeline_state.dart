part of 'pipeline_bloc.dart';

enum PipelineStatus { initial, loading, refreshing, ready, failed }

class PipelineState extends Equatable {
  const PipelineState({
    this.status = PipelineStatus.initial,
    this.board = PipelineBoard.empty,
    this.search = '',
    this.stage,
    this.openLead,
    this.openLeadId = '',
    this.leadBusy = false,
    this.error = '',
  });

  final PipelineStatus status;
  final PipelineBoard board;
  final String search;

  /// null means "every stage".
  final Stage? stage;

  final Lead? openLead;
  final String openLeadId;
  final bool leadBusy;
  final String error;

  bool get isLoading => status == PipelineStatus.loading;
  bool get isRefreshing => status == PipelineStatus.refreshing;

  /// The leads the board should render right now.
  List<Lead> get visible =>
      stage == null ? board.leads : board.inStage(stage!);

  PipelineState copyWith({
    PipelineStatus? status,
    PipelineBoard? board,
    String? search,
    Stage? stage,
    bool clearStage = false,
    Lead? openLead,
    String? openLeadId,
    bool clearOpenLead = false,
    bool? leadBusy,
    String? error,
  }) =>
      PipelineState(
        status: status ?? this.status,
        board: board ?? this.board,
        search: search ?? this.search,
        stage: clearStage ? null : (stage ?? this.stage),
        openLead: clearOpenLead ? null : (openLead ?? this.openLead),
        openLeadId: clearOpenLead ? '' : (openLeadId ?? this.openLeadId),
        leadBusy: leadBusy ?? this.leadBusy,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props =>
      <Object?>[status, board, search, stage, openLead, openLeadId, leadBusy, error];
}
