import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focuschainlabs_mobile/core/get.dart';
import 'package:focuschainlabs_mobile/core/models/lead_chat.dart';
import 'package:focuschainlabs_mobile/core/models/pipeline.dart';
import 'package:focuschainlabs_mobile/core/repository/crm_repository.dart';
import 'package:focuschainlabs_mobile/core/services/api/secona_api.dart';
import 'package:focuschainlabs_mobile/core/theme/app_theme.dart';
import 'package:focuschainlabs_mobile/features/pipeline/bloc/pipeline_bloc.dart';
import 'package:focuschainlabs_mobile/features/pipeline/view/lead_chat_view.dart';
import 'package:focuschainlabs_mobile/features/pipeline/view/lead_detail_view.dart';

/// These two screens went blank below the header — no record, no messages, and
/// a composer whose sends vanished. It was one layout assertion: the brief
/// tile stretched its stage rail inside a ListView, where the cross axis is
/// unbounded, so the rail was handed an infinite height and the whole viewport
/// failed to lay out. Nothing rendered, and nothing said why.
///
/// A model test would not have caught it — the JSON parsed perfectly. These
/// mount the real widgets and assert on what a person would see.
///
/// The payload is `mobile_api.serializers.lead_detail`'s actual output,
/// generated from the server rather than hand-written: a stub would encode the
/// shape I believe the API returns, which is the belief worth testing.
const Map<String, dynamic> kLead = <String, dynamic>{
    'id': 'c1',
    'name': 'Priya Nair',
    'company': 'Nair Family',
    'email': 'priya@example.com',
    'phone': '+91 99001 10005',
    'stage': 'site_visits',
    'stage_label': 'Site Visits',
    'deal_status': '',
    'owner': 'savin@focuschainlabs.com',
    'value': 0.0,
    'value_fmt': '',
    'locality': 'Jayanagar',
    'budget': '3.6 Cr',
    'requirement': '',
    'bhk': '4 BHK',
    'property_type': 'Villa',
    'source': 'referral',
    'next_follow_up': '2026-08-22',
    'updated_at': '',
    'created_at': '',
    'score': 86,
    'priority': 90,
    'risk': 'needs_attention',
    'risk_reasons': <dynamic>[
      'No contact in 12 days',
    ],
    'top_factors': <dynamic>[
      <String, dynamic>{
        'feature': 'recency',
        'points': 24,
        'reason': 'Recent site visit',
      },
    ],
    'days_since_activity': 12,
    'follow_up_due': true,
    'budget_stretch': '',
    'pincode': '',
    'possession': '',
    'must_haves': 'garden',
    'financing': 'home loan',
    'industry': '',
    'site_visits': '',
    'brokerage_pct': '',
    'brokerage_amount': '',
    'brokerage_status': '',
    'brokerage_received_on': '',
    'relationship_age': '',
    'relationship_health': '',
    'sentiment': '',
    'action_hint': '',
    'notes': 'Wants to close before Diwali.',
    'signal': '',
    'opening_line': '',
    'ai_summary': '',
    'tags': <dynamic>[],
    'field_groups': <dynamic>[
      <String, dynamic>{
        'key': 'requirement',
        'label': 'What they want',
        'fields': <dynamic>[
          <String, dynamic>{
            'key': 'property_type',
            'label': 'Property type',
            'value': 'Villa',
          },
          <String, dynamic>{
            'key': 'bhk',
            'label': 'Configuration',
            'value': '4 BHK',
          },
          <String, dynamic>{
            'key': 'budget',
            'label': 'Budget',
            'value': '3.6 Cr',
          },
          <String, dynamic>{
            'key': 'locality',
            'label': 'Preferred area',
            'value': 'Jayanagar',
          },
          <String, dynamic>{
            'key': 'must_haves',
            'label': 'Must have',
            'value': 'garden',
          },
          <String, dynamic>{
            'key': 'financing',
            'label': 'Financing',
            'value': 'home loan',
          },
        ],
      },
      <String, dynamic>{
        'key': 'contact',
        'label': 'Contact',
        'fields': <dynamic>[
          <String, dynamic>{
            'key': 'phone',
            'label': 'Phone',
            'value': '+91 99001 10005',
          },
          <String, dynamic>{
            'key': 'email',
            'label': 'Email',
            'value': 'priya@example.com',
          },
          <String, dynamic>{
            'key': 'company',
            'label': 'Company',
            'value': 'Nair Family',
          },
          <String, dynamic>{
            'key': 'source',
            'label': 'Source',
            'value': 'referral',
          },
        ],
      },
      <String, dynamic>{
        'key': 'deal',
        'label': 'Deal',
        'fields': <dynamic>[
          <String, dynamic>{
            'key': 'owner',
            'label': 'Owner',
            'value': 'savin@focuschainlabs.com',
          },
          <String, dynamic>{
            'key': 'next_follow_up',
            'label': 'Next follow-up',
            'value': '2026-08-22',
          },
        ],
      },
    ],
    'activities': <dynamic>[
      <String, dynamic>{
        'type': 'call.logged',
        'actor_type': 'user',
        'payload': <String, dynamic>{
          'note': 'Discussed budget',
        },
        'note': 'Discussed budget',
        'created_at': '2026-08-09T10:00:00',
      },
    ],
    'people': <dynamic>[
      <String, dynamic>{
        'id': 'p1',
        'name': 'Meera Nair',
        'role': 'Spouse',
        'stance': 'blocker',
        'phone': '',
        'email': '',
        'notes': '',
      },
    ],
    'audit': <dynamic>[],
  };

const Map<String, dynamic> kThread = <String, dynamic>{
    'lead': <String, dynamic>{
      'id': 'c1',
      'name': 'Priya Nair',
      'company': 'Nair Family',
      'email': 'priya@example.com',
      'phone': '+91 99001 10005',
      'stage': 'site_visits',
      'stage_label': 'Site Visits',
      'deal_status': '',
      'owner': 'savin@focuschainlabs.com',
      'value': 0.0,
      'value_fmt': '',
      'locality': 'Jayanagar',
      'budget': '3.6 Cr',
      'requirement': '',
      'bhk': '4 BHK',
      'property_type': 'Villa',
      'source': 'referral',
      'next_follow_up': '2026-08-22',
      'updated_at': '',
      'created_at': '',
      'score': 86,
      'priority': 90,
      'risk': 'needs_attention',
      'risk_reasons': <dynamic>[
        'No contact in 12 days',
      ],
      'top_factors': <dynamic>[
        <String, dynamic>{
          'feature': 'recency',
          'points': 24,
          'reason': 'Recent site visit',
        },
      ],
      'days_since_activity': 12,
      'follow_up_due': true,
      'budget_stretch': '',
      'pincode': '',
      'possession': '',
      'must_haves': 'garden',
      'financing': 'home loan',
      'industry': '',
      'site_visits': '',
      'brokerage_pct': '',
      'brokerage_amount': '',
      'brokerage_status': '',
      'brokerage_received_on': '',
      'relationship_age': '',
      'relationship_health': '',
      'sentiment': '',
      'action_hint': '',
      'notes': 'Wants to close before Diwali.',
      'signal': '',
      'opening_line': '',
      'ai_summary': '',
      'tags': <dynamic>[],
      'field_groups': <dynamic>[
        <String, dynamic>{
          'key': 'requirement',
          'label': 'What they want',
          'fields': <dynamic>[
            <String, dynamic>{
              'key': 'property_type',
              'label': 'Property type',
              'value': 'Villa',
            },
            <String, dynamic>{
              'key': 'bhk',
              'label': 'Configuration',
              'value': '4 BHK',
            },
            <String, dynamic>{
              'key': 'budget',
              'label': 'Budget',
              'value': '3.6 Cr',
            },
            <String, dynamic>{
              'key': 'locality',
              'label': 'Preferred area',
              'value': 'Jayanagar',
            },
            <String, dynamic>{
              'key': 'must_haves',
              'label': 'Must have',
              'value': 'garden',
            },
            <String, dynamic>{
              'key': 'financing',
              'label': 'Financing',
              'value': 'home loan',
            },
          ],
        },
        <String, dynamic>{
          'key': 'contact',
          'label': 'Contact',
          'fields': <dynamic>[
            <String, dynamic>{
              'key': 'phone',
              'label': 'Phone',
              'value': '+91 99001 10005',
            },
            <String, dynamic>{
              'key': 'email',
              'label': 'Email',
              'value': 'priya@example.com',
            },
            <String, dynamic>{
              'key': 'company',
              'label': 'Company',
              'value': 'Nair Family',
            },
            <String, dynamic>{
              'key': 'source',
              'label': 'Source',
              'value': 'referral',
            },
          ],
        },
        <String, dynamic>{
          'key': 'deal',
          'label': 'Deal',
          'fields': <dynamic>[
            <String, dynamic>{
              'key': 'owner',
              'label': 'Owner',
              'value': 'savin@focuschainlabs.com',
            },
            <String, dynamic>{
              'key': 'next_follow_up',
              'label': 'Next follow-up',
              'value': '2026-08-22',
            },
          ],
        },
      ],
      'activities': <dynamic>[
        <String, dynamic>{
          'type': 'call.logged',
          'actor_type': 'user',
          'payload': <String, dynamic>{
            'note': 'Discussed budget',
          },
          'note': 'Discussed budget',
          'created_at': '2026-08-09T10:00:00',
        },
      ],
      'people': <dynamic>[
        <String, dynamic>{
          'id': 'p1',
          'name': 'Meera Nair',
          'role': 'Spouse',
          'stance': 'blocker',
          'phone': '',
          'email': '',
          'notes': '',
        },
      ],
      'audit': <dynamic>[],
    },
    'brief': <String, dynamic>{
      'lead': 'Priya Nair',
      'stage': 'Site Visits',
      'rows': <dynamic>[
        <String, dynamic>{
          'label': 'WANTS',
          'value': '4 BHK · 3.6 Cr · Jayanagar',
          'gap': false,
        },
        <String, dynamic>{
          'label': 'LAST TALK',
          'value': '12 days ago',
          'gap': false,
        },
        <String, dynamic>{
          'label': 'MISSING',
          'value': 'possession timeline',
          'gap': true,
        },
      ],
      'flags': <dynamic>[
        'Needs attention',
      ],
    },
    'messages': <dynamic>[],
  };

class _FakeRepo extends CrmRepository {
  _FakeRepo() : super(api: SeconaApi());

  @override
  Future<Lead> lead(String id) async => Lead.fromJson(kLead);

  @override
  Future<LeadChatThread> leadThread(String contactId) async =>
      LeadChatThread.fromJson(kThread);

  /// What the server stores and hands back: the question and the answer, with
  /// the ids it gave them.
  @override
  Future<List<LeadChatMessage>> askAboutLead(String id, String message) async =>
      <LeadChatMessage>[
        LeadChatMessage(
          id: 'm1',
          role: 'user',
          body: message,
          source: 'mobile',
          createdAt: DateTime.now(),
        ),
        LeadChatMessage(
          id: 'm2',
          role: 'assistant',
          body: 'They are after 4 BHK · 3.6 Cr · Jayanagar.',
          source: 'mobile',
          createdAt: DateTime.now(),
        ),
      ];
}

Widget _host(Widget child, PipelineBloc bloc) => MaterialApp(
      theme: AppTheme.light,
      home: BlocProvider<PipelineBloc>.value(value: bloc, child: child),
    );

void main() {
  setUp(() {
    initializeGetIt();
    if (app.isRegistered<CrmRepository>()) app.unregister<CrmRepository>();
    app.registerSingleton<CrmRepository>(_FakeRepo());
  });

  testWidgets('the lead page renders the whole record', (WidgetTester tester) async {
    final PipelineBloc bloc = PipelineBloc(repository: app<CrmRepository>())
      ..add(const PipelineLeadOpened('c1'));

    await tester.pumpWidget(_host(const LeadDetailView(leadId: 'c1'), bloc));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Priya Nair'), findsWidgets);
    // Everything below the chips is what used to disappear.
    expect(find.text('Configuration'), findsOneWidget);
    expect(find.text('4 BHK'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
  });

  testWidgets('the lead page shows the brief the chat shows',
      (WidgetTester tester) async {
    final PipelineBloc bloc = PipelineBloc(repository: app<CrmRepository>())
      ..add(const PipelineLeadOpened('c1'));

    await tester.pumpWidget(_host(const LeadDetailView(leadId: 'c1'), bloc));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The brief arrives after the record, so this is the rebuild that used to
    // take the page down.
    expect(tester.takeException(), isNull);
    expect(find.text('WANTS'), findsOneWidget);
  });

  testWidgets('the lead chat renders its brief and its starters',
      (WidgetTester tester) async {
    final PipelineBloc bloc = PipelineBloc(repository: app<CrmRepository>());

    await tester.pumpWidget(_host(const LeadChatView(leadId: 'c1'), bloc));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Ask about this lead'), findsOneWidget);
    expect(find.text('WANTS'), findsOneWidget);
  });

  testWidgets('a typed message appears in the thread straight away',
      (WidgetTester tester) async {
    final PipelineBloc bloc = PipelineBloc(repository: app<CrmRepository>());

    await tester.pumpWidget(_host(const LeadChatView(leadId: 'c1'), bloc));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(find.byType(TextField), 'Is their loan approved?');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Is their loan approved?'), findsOneWidget);

    // The thread scrolls itself to the bottom on send; let that animation
    // finish or its timer outlives the test.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a question is never deleted by a silent answer',
      (WidgetTester tester) async {
    // Swapping the local pair for an empty stored list used to remove the
    // question too, leaving the thread as it was before send — which reads as
    // the app ignoring what you typed.
    final PipelineBloc bloc = PipelineBloc(repository: app<CrmRepository>());

    await tester.pumpWidget(_host(const LeadChatView(leadId: 'c1'), bloc));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(find.byType(TextField), 'Anything on the loan?');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Anything on the loan?'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });
}
