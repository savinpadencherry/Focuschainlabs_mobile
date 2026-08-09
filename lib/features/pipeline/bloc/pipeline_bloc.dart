import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/pipeline.dart';
import '../../../core/repository/crm_repository.dart';
import '../../../core/services/api/secona_api.dart';

part 'pipeline_event.dart';
part 'pipeline_state.dart';

/// The pipeline board and the lead currently open on it.
class PipelineBloc extends Bloc<PipelineEvent, PipelineState> {
  PipelineBloc({required CrmRepository repository})
      : _repository = repository,
        super(const PipelineState()) {
    on<PipelineLoaded>(_onLoaded);
    on<PipelineSearched>(_onSearched);
    on<PipelineStageFiltered>(_onStageFiltered);
    on<PipelineLeadOpened>(_onLeadOpened);
    on<PipelineLeadClosed>(_onLeadClosed);
    on<PipelineStageChanged>(_onStageChanged);
    on<PipelineNoteLogged>(_onNoteLogged);
  }

  final CrmRepository _repository;

  Future<void> _onLoaded(PipelineLoaded event, Emitter<PipelineState> emit) async {
    emit(state.copyWith(
      status: state.board.leads.isEmpty
          ? PipelineStatus.loading
          : PipelineStatus.refreshing,
      error: '',
    ));
    try {
      final PipelineBoard board = await _repository.board(search: state.search);
      emit(state.copyWith(status: PipelineStatus.ready, board: board));
    } on ApiException catch (e) {
      emit(state.copyWith(status: PipelineStatus.failed, error: e.message));
    }
  }

  Future<void> _onSearched(
    PipelineSearched event,
    Emitter<PipelineState> emit,
  ) async {
    emit(state.copyWith(search: event.query));
    add(const PipelineLoaded());
  }

  void _onStageFiltered(PipelineStageFiltered event, Emitter<PipelineState> emit) {
    // Filtering is local: the board is already loaded and an org's pipeline is
    // hundreds of rows, not thousands. A round trip per tab tap would make the
    // board feel slower than the browser it is mirroring.
    emit(state.copyWith(stage: event.stage, clearStage: event.stage == null));
  }

  Future<void> _onLeadOpened(
    PipelineLeadOpened event,
    Emitter<PipelineState> emit,
  ) async {
    emit(state.copyWith(leadBusy: true, openLeadId: event.id, error: ''));
    try {
      final Lead lead = await _repository.lead(event.id);
      emit(state.copyWith(openLead: lead, leadBusy: false));
    } on ApiException catch (e) {
      emit(state.copyWith(leadBusy: false, error: e.message));
    }
  }

  void _onLeadClosed(PipelineLeadClosed event, Emitter<PipelineState> emit) {
    emit(state.copyWith(clearOpenLead: true));
  }

  Future<void> _onStageChanged(
    PipelineStageChanged event,
    Emitter<PipelineState> emit,
  ) async {
    emit(state.copyWith(leadBusy: true, error: ''));
    try {
      final Lead stored = await _repository.moveStage(event.id, event.stage);
      // The board's counts and the lead's stage both changed, so both are
      // re-read rather than patched locally — a board that disagrees with the
      // lead it just moved is the bug this avoids.
      emit(state.copyWith(openLead: stored, leadBusy: false));
      add(const PipelineLoaded());
    } on ApiException catch (e) {
      emit(state.copyWith(leadBusy: false, error: e.message));
    }
  }

  Future<void> _onNoteLogged(
    PipelineNoteLogged event,
    Emitter<PipelineState> emit,
  ) async {
    emit(state.copyWith(leadBusy: true, error: ''));
    try {
      final Lead stored = await _repository.logActivity(event.id, event.note);
      emit(state.copyWith(openLead: stored, leadBusy: false));
      add(const PipelineLoaded());
    } on ApiException catch (e) {
      emit(state.copyWith(leadBusy: false, error: e.message));
    }
  }
}
