import '../../models/crm.dart';
import '../../models/extraction.dart';

/// Contract for talking to the Leads Agent CRM. The HTTP implementation calls
/// the FastAPI service (deployed on Render) which reuses the CRM's existing
/// `load_crm`/`_upsert_contact`/`save_crm` functions; a mock backs demo mode.
abstract interface class LeadsCrmService {
  /// Upsert a lead and append the spoken update as an interaction (F2/F5).
  Future<CrmWriteResult> upsertLead(Extraction extraction, {String? transcript});

  /// Fetch a contact's interaction history for the "show the history" view.
  Future<List<CrmInteraction>> history(String contactRef);
}
