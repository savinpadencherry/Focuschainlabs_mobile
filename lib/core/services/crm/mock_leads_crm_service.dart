import '../../constants/app_constants.dart';
import '../../data/seed_data.dart';
import '../../models/crm.dart';
import '../../models/enums.dart';
import '../../models/extraction.dart';
import 'leads_crm_service.dart';

/// Offline stand-in for the CRM API: echoes a successful write and serves a
/// short synthetic history so the lead → CRM-update flow is demonstrable with
/// no backend.
class MockLeadsCrmService implements LeadsCrmService {
  const MockLeadsCrmService();

  @override
  Future<CrmWriteResult> upsertLead(
    Extraction extraction, {
    String? transcript,
  }) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return CrmWriteResult(
      ok: true,
      contactId: extraction.client.toLowerCase().replaceAll(RegExp(r'\s+'), '-'),
      contactName: extraction.client,
      action: 'merged',
    );
  }

  @override
  Future<List<CrmContact>> listLeads() async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return SeedData.clients()
        .map((c) => CrmContact(
              id: c.id,
              name: c.name,
              company: c.name,
              status: c.primaryDeal?.stage.label ?? 'New',
              dealStatus: 'open',
              value: c.primaryDeal?.value ?? '',
              owner: c.owner,
            ))
        .toList();
  }

  @override
  Future<bool> updateStatus(String contactId, String newStatus) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return true;
  }

  @override
  Future<List<CrmInteraction>> history(String contactRef) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final DateTime now = DateTime.now();
    return <CrmInteraction>[
      CrmInteraction(
        body: 'Logged from mobile just now.',
        createdAt: now,
        author: 'Mr. Rex (mobile)',
      ),
      CrmInteraction(
        body: 'Discovery call — wants a revised quote by Friday.',
        createdAt: now.subtract(const Duration(hours: 3)),
        author: 'Savin',
      ),
      CrmInteraction(
        body: 'Sent configurator scope deck.',
        createdAt: now.subtract(const Duration(days: 2)),
        author: 'Savin',
      ),
    ];
  }
}
