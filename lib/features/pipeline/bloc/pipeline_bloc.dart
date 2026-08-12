import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/get.dart';
import '../../../core/models/pipeline.dart';
import '../../../core/repository/crm_repository.dart';
import '../../../core/services/api/secona_api.dart';
import '../../../core/services/firebase/analytics_service.dart';

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
    // Whether people search at all, not what for — a search term in a CRM is
    // usually a client's name.
    if (event.query.isNotEmpty) {
      app<AnalyticsService>().log(AnalyticsEvents.leadSearched);
    }
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
      app<AnalyticsService>().log(AnalyticsEvents.leadOpened);
    } on ApiException catch (e) {
      emit(state.copyWith(leadBusy: false, error: e.message));
      app<AnalyticsService>().log(
        AnalyticsEvents.apiFailed,
        <String, Object>{'where': 'lead_open', 'status': e.statusCode},
      );
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
      // The stage name is a fixed vocabulary, not a person — safe to count.
      app<AnalyticsService>().log(
        AnalyticsEvents.leadStageChanged,
        <String, Object>{'stage': event.stage.key},
      );
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
      app<AnalyticsService>().log(
        AnalyticsEvents.leadNoteLogged,
        <String, Object>{'length': event.note.length},
      );
      emit(state.copyWith(openLead: stored, leadBusy: false));
      add(const PipelineLoaded());
    } on ApiException catch (e) {
      emit(state.copyWith(leadBusy: false, error: e.message));
    }
  }
}
