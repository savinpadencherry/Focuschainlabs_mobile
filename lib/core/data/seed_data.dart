import '../models/activity.dart';
import '../models/client.dart';
import '../models/enums.dart';
import '../models/meeting.dart';
import '../models/user.dart';

/// Seeded demo data for FCL (tenant zero). Replaced by Supabase queries once
/// the backend is wired — repositories are the only place that touch this.
abstract final class SeedData {
  static DateTime _at(int hour, int minute, {int dayOffset = 0}) {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
  }

  static const AppUser user = AppUser(
    id: 'usr-savin',
    name: 'Savin Padencherry',
    email: 'savin@focuschainlabs.com',
    orgId: 'org-fcl',
    orgName: 'FocusChain Labs',
    role: UserRole.admin,
  );

  static List<Client> clients() => <Client>[
        Client(
          id: 'cl-acme',
          name: 'Acme Corp',
          industry: 'Manufacturing',
          owner: 'Savin',
          sentiment: Sentiment.positive,
          contacts: const <Contact>[
            Contact(name: 'Priya Nair', title: 'Head of Ops', email: 'priya@acme.com'),
            Contact(name: 'Rohit Verma', title: 'Procurement Lead'),
          ],
          deals: const <Deal>[
            Deal(
              title: 'Configurator rollout',
              stage: DealStage.proposal,
              value: '₹8.5L',
              sentiment: Sentiment.positive,
            ),
          ],
          interactions: <Interaction>[
            Interaction(
              summary: 'Discovery call — wants a revised quote by Friday.',
              date: _at(11, 30),
              type: UpdateType.interaction,
            ),
            Interaction(
              summary: 'Sent configurator scope deck.',
              date: _at(15, 0, dayOffset: -2),
              type: UpdateType.comment,
            ),
          ],
          recentEmailSubjects: const <String>[
            'Re: Revised quote for configurator',
            'Scope deck — a few questions',
          ],
          pendingFollowUps: const <String>['Send revised quote (Fri)'],
        ),
        Client(
          id: 'cl-northstar',
          name: 'Northstar Industries',
          industry: 'Logistics',
          owner: 'Savin',
          sentiment: Sentiment.neutral,
          contacts: const <Contact>[
            Contact(name: 'Meera Iyer', title: 'VP Sales'),
          ],
          deals: const <Deal>[
            Deal(title: 'Pilot — 2 depots', stage: DealStage.qualified, value: '₹4.2L'),
          ],
          interactions: <Interaction>[
            Interaction(
              summary: 'Product walkthrough completed.',
              date: _at(16, 0, dayOffset: -1),
              type: UpdateType.interaction,
            ),
          ],
          recentEmailSubjects: const <String>['Pilot timeline?'],
          pendingFollowUps: const <String>['Share pilot SOW'],
        ),
        Client(
          id: 'cl-zephyr',
          name: 'Zephyr Retail',
          industry: 'Retail',
          owner: 'Bhaskar',
          sentiment: Sentiment.atRisk,
          contacts: const <Contact>[
            Contact(name: 'Anand Rao', title: 'Founder'),
          ],
          deals: const <Deal>[
            Deal(
              title: 'Annual licence',
              stage: DealStage.negotiation,
              value: '₹12L',
              sentiment: Sentiment.atRisk,
            ),
          ],
          interactions: <Interaction>[
            Interaction(
              summary: 'Pushed back on pricing; comparing alternatives.',
              date: _at(10, 0, dayOffset: -3),
              type: UpdateType.interaction,
            ),
          ],
          recentEmailSubjects: const <String>['Pricing concerns'],
          pendingFollowUps: const <String>['Re-engage with revised pricing'],
        ),
      ];

  static List<Meeting> meetings() => <Meeting>[
        Meeting(
          id: 'mtg-acme',
          title: 'Acme discovery call',
          clientName: 'Acme Corp',
          start: _at(11, 30),
          durationMinutes: 45,
          platform: 'Google Meet',
          attendees: const <String>['priya@acme.com', 'savin@focuschainlabs.com'],
        ),
        Meeting(
          id: 'mtg-standup',
          title: 'FCL internal stand-up',
          clientName: 'Internal',
          start: _at(9, 30),
          durationMinutes: 15,
          platform: 'Google Meet',
          captureEligible: false,
        ),
        Meeting(
          id: 'mtg-northstar',
          title: 'Northstar pilot review',
          clientName: 'Northstar Industries',
          start: _at(17, 30),
          durationMinutes: 30,
          platform: 'Zoom',
          attendees: const <String>['meera@northstar.com'],
        ),
      ];

  /// Product / service knowledge base entries for F1 grounded answers.
  static const Map<String, String> productKnowledge = <String, String>{
    'configurator':
        'The configurator scope covers guided product selection, rule-based '
            'pricing and an exportable spec sheet. Typical price band: ₹6L–₹10L '
            'depending on rule complexity and integrations.',
    'pricing':
        'Standard pricing is a near-fixed monthly platform fee plus usage-based '
            'AI tokens — no per-message charges. MSME pilots start at a reduced '
            'design-partner rate.',
    'pilot':
        'Pilots run 4–6 weeks on up to two sites, with a fixed scope statement '
            'and a success metric agreed up front.',
  };

  static List<Integration> integrations() => const <Integration>[
        Integration(
          name: 'Google Calendar',
          category: 'Calendar',
          status: ConnectionStatus.connected,
          detail: 'Meeting detection active',
        ),
        Integration(
          name: 'Built-in CRM',
          category: 'CRM',
          status: ConnectionStatus.connected,
          detail: 'System of record',
        ),
        Integration(
          name: 'Trello',
          category: 'Task tool',
          status: ConnectionStatus.pending,
          detail: 'Connect to push action items',
        ),
        Integration(
          name: 'Gmail',
          category: 'Email',
          status: ConnectionStatus.pending,
          detail: 'Read-only context (F8)',
        ),
      ];
}
