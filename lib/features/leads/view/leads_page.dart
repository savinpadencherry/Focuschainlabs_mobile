import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/config/app_config.dart';
import '../../../core/get.dart';
import '../../../core/models/crm.dart';
import '../../../core/services/crm/leads_crm_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/mono_label.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/web_view_screen.dart';
import '../../prep/view/prep_view.dart';

/// The in-app Leads list, pulled live from the Leads Agent CRM
/// (`data/crm/contacts.json` in the repo). Tapping a lead opens the CRM in the
/// desktop-view webview.
class LeadsPage extends StatefulWidget {
  const LeadsPage({super.key});

  @override
  State<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage> {
  late Future<List<CrmContact>> _future = app<LeadsCrmService>().listLeads();

  void _refresh() => setState(() {
        _future = app<LeadsCrmService>().listLeads();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ContentBounds(
          child: FutureBuilder<List<CrmContact>>(
            future: _future,
            builder: (BuildContext context, AsyncSnapshot<List<CrmContact>> snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const LoadingView(label: 'Pulling leads from the CRM…');
              }
              final List<CrmContact> leads = snap.data ?? <CrmContact>[];
              if (leads.isEmpty) {
                return const EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'No leads yet',
                  message: 'New leads you capture will land here and in your CRM repo.',
                );
              }
              return _LeadsList(leads: leads, onRefresh: _refresh);
            },
          ),
        ),
      ),
    );
  }
}

class _LeadsList extends StatelessWidget {
  const _LeadsList({required this.leads, required this.onRefresh});

  final List<CrmContact> leads;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
        children: <Widget>[
          MonoLabel('${leads.length} leads · live from CRM', color: AppColors.inkSoft),
          AppSpacing.vGapMd,
          ...leads.map((CrmContact c) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _LeadCard(contact: c),
              )),
        ].animate(interval: 50.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.contact});

  final CrmContact contact;

  void _open(BuildContext context) {
    if (!AppConfig.hasCrmWeb) return;
    WebViewScreen.open(
      context,
      url: AppConfig.crmWebUrl,
      title: '${contact.name} · CRM',
      desktopView: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => _open(context),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.logoGradient),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            alignment: Alignment.center,
            child: Text(
              contact.name.isEmpty ? '?' : contact.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  contact.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  <String>[
                    if (contact.company.isNotEmpty) contact.company,
                    if (contact.status.isNotEmpty) contact.status,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                ),
              ],
            ),
          ),
          if (contact.value.isNotEmpty)
            Text(
              contact.value,
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.green),
            ),
          IconButton(
            tooltip: 'Prep me for a call',
            visualDensity: VisualDensity.compact,
            onPressed: () => PrepView.open(context, contact.name),
            icon: const Icon(Icons.auto_awesome_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}
