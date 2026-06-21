import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/client_brief.dart';
import '../../../core/models/crm.dart';
import '../../../core/services/ai/ai_service.dart';
import '../../../core/services/crm/leads_crm_service.dart';
import '../../../core/utils/formatters.dart';

enum PrepStatus { loading, ready, error }

class PrepState extends Equatable {
  const PrepState({
    this.status = PrepStatus.loading,
    this.brief,
    this.contact,
    this.message,
  });

  final PrepStatus status;
  final ClientBrief? brief;

  /// The matched CRM contact (deal value/status) shown in the header.
  final CrmContact? contact;
  final String? message;

  PrepState copyWith({
    PrepStatus? status,
    ClientBrief? brief,
    CrmContact? contact,
    String? message,
  }) =>
      PrepState(
        status: status ?? this.status,
        brief: brief ?? this.brief,
        contact: contact ?? this.contact,
        message: message,
      );

  @override
  List<Object?> get props => <Object?>[status, brief, contact, message];
}

/// Drives "prep me" mode: pulls the client's recent CRM history + open-deal
/// info and asks Gemini for a grounded pre-call briefing.
class PrepCubit extends Cubit<PrepState> {
  PrepCubit({
    required AiService ai,
    required LeadsCrmService crm,
    required this.clientName,
  })  : _ai = ai,
        _crm = crm,
        super(const PrepState());

  final AiService _ai;
  final LeadsCrmService _crm;
  final String clientName;

  Future<void> load() async {
    emit(const PrepState(status: PrepStatus.loading));
    try {
      final CrmContact? contact = await _resolveContact();
      final List<CrmInteraction> history = await _crm.history(clientName);
      final String context = _buildContext(contact, history);
      final ClientBrief brief =
          await _ai.brief(clientName: clientName, context: context);
      emit(PrepState(
        status: PrepStatus.ready,
        brief: brief,
        contact: contact,
      ));
    } catch (_) {
      emit(const PrepState(
        status: PrepStatus.error,
        message: 'Couldn’t prep this client just now — please try again.',
      ));
    }
  }

  Future<CrmContact?> _resolveContact() async {
    try {
      final List<CrmContact> contacts = await _crm.listLeads();
      final String needle = clientName.toLowerCase();
      final String first = needle.split(' ').first;
      for (final CrmContact c in contacts) {
        final String hay = c.name.toLowerCase();
        if (hay == needle ||
            hay.contains(needle) ||
            (first.length > 2 && hay.contains(first))) {
          return c;
        }
      }
    } catch (_) {/* best-effort */}
    return null;
  }

  String _buildContext(CrmContact? contact, List<CrmInteraction> history) {
    final StringBuffer buf = StringBuffer();
    if (contact != null) {
      final List<String> deal = <String>[
        if (contact.company.trim().isNotEmpty) 'company ${contact.company}',
        if (contact.value.trim().isNotEmpty) 'deal value ${contact.value}',
        if (contact.dealStatus.trim().isNotEmpty)
          'deal status ${contact.dealStatus}'
        else if (contact.status.trim().isNotEmpty)
          'status ${contact.status}',
        if (contact.owner.trim().isNotEmpty) 'owner ${contact.owner}',
      ];
      if (deal.isNotEmpty) buf.writeln('Deal: ${deal.join(', ')}.');
    }
    if (history.isEmpty) {
      buf.writeln('No prior interactions are logged for $clientName yet.');
    } else {
      buf.writeln('Recent interactions:');
      for (final CrmInteraction i in history.take(6)) {
        buf.writeln('- ${Formatters.dayShort(i.createdAt)}: ${i.body}');
      }
    }
    return buf.toString().trim();
  }
}
