import 'package:flutter_test/flutter_test.dart';

import 'package:focuschainlabs_mobile/core/models/listing.dart';
import 'package:focuschainlabs_mobile/core/models/pipeline.dart';

void main() {
  group('access comes from the server', () {
    test('a manager sees aggregates, and the app can say so', () {
      final Access access = Access.fromJson(<String, dynamic>{
        'scope': 'aggregate',
        'can_edit_leads': false,
      });
      expect(access.seesAggregatesOnly, isTrue);
      expect(access.canEditLeads, isFalse);
      expect(access.scopeLabel, contains('Totals'));
    });

    test('an API that says nothing about access does not lock the app down', () {
      // The server is the gate. Guessing generously costs a rejected write;
      // guessing meanly costs a rep a button they are entitled to.
      final Me me = Me.fromJson(<String, dynamic>{'email': 'a@b.com'});
      expect(me.access, Access.unknown);
      expect(me.access.canEditLeads, isTrue);
      expect(me.access.seesAggregatesOnly, isFalse);
    });

    test('an empty allowlist means the server did not say', () {
      expect(Access.unknown.canEditLeadField('bhk'), isTrue);
      const Access stated = Access(editableLeadFields: <String>['name', 'phone']);
      expect(stated.canEditLeadField('name'), isTrue);
      expect(stated.canEditLeadField('bhk'), isFalse);
    });

    test('the organisation is read off the payload, never assumed', () {
      final Me me = Me.fromJson(<String, dynamic>{
        'email': 'rep@acme.com',
        'role': 'rep',
        'organization_id': 'acme',
        'organization': <String, dynamic>{
          'name': 'Acme Realty',
          'vertical': 'real_estate',
          'timezone': 'Asia/Kolkata',
          'dial_code': '91',
        },
        'access': <String, dynamic>{'scope': 'own'},
      });
      expect(me.organizationId, 'acme');
      expect(me.organizationName, 'Acme Realty');
      expect(me.timezone, 'Asia/Kolkata');
      expect(me.isRealEstate, isTrue);
    });
  });

  group('a lead carries everything on its record', () {
    Lead parse(Map<String, dynamic> json) => Lead.fromJson(<String, dynamic>{
          'id': 'c1',
          'name': 'Arjun',
          'stage': 'offer',
          ...json,
        });

    test('the structured requirement fields survive the trip', () {
      final Lead lead = parse(<String, dynamic>{
        'bhk': '3 BHK',
        'property_type': 'Apartment',
        'possession': 'Ready to move',
      });
      expect(lead.bhk, '3 BHK');
      expect(lead.propertyType, 'Apartment');
      expect(lead.possession, 'Ready to move');
    });

    test('the server decides which section a field belongs to', () {
      final Lead lead = parse(<String, dynamic>{
        'field_groups': <dynamic>[
          <String, dynamic>{
            'key': 'requirement',
            'label': 'What they want',
            'fields': <dynamic>[
              <String, dynamic>{'key': 'bhk', 'label': 'Configuration', 'value': '3 BHK'},
            ],
          },
        ],
      });
      expect(lead.fieldGroups.single.label, 'What they want');
      expect(lead.fieldGroups.single.fields.single.label, 'Configuration');
    });

    test('a board summary has no groups, so the page must fall back', () {
      expect(parse(<String, dynamic>{}).fieldGroups, isEmpty);
    });

    test('a blocker is identifiable before the call is made', () {
      final Lead lead = parse(<String, dynamic>{
        'people': <dynamic>[
          <String, dynamic>{
            'name': 'Meera',
            'role': 'Spouse',
            'stance': 'blocker',
          },
        ],
      });
      final LeadPerson person = lead.people.single;
      expect(person.isBlocker, isTrue);
      expect(person.isChampion, isFalse);
      expect(person.subtitle, 'Spouse · blocker');
    });

    test('a person with no stance still reads as a person', () {
      final Lead lead = parse(<String, dynamic>{
        'people': <dynamic>[
          <String, dynamic>{'name': 'Raj', 'role': 'Brother', 'stance': ''},
        ],
      });
      expect(lead.people.single.subtitle, 'Brother');
      expect(lead.people.single.isBlocker, isFalse);
    });
  });

  group('listing photos', () {
    test('the count decides whether there is a gallery', () {
      final Listing listing = Listing.fromJson(<String, dynamic>{
        'id': 'l1',
        'photo_count': 4,
      });
      expect(listing.photoCount, 4);
      expect(listing.hasPhotos, isTrue);
    });

    test('an older API without a count falls back to the references', () {
      final Listing listing = Listing.fromJson(<String, dynamic>{
        'id': 'l1',
        'images': <dynamic>['gcs:a', 'gcs:b'],
      });
      expect(listing.photoCount, 2);
    });

    test('no photos is not a gallery', () {
      expect(Listing.fromJson(<String, dynamic>{'id': 'l1'}).hasPhotos, isFalse);
    });
  });

  group('the search a filter actually sends', () {
    test('an unset budget is not sent as a filter', () {
      // The API client drops a value of exactly '0'; a double stringifies as
      // "0.0", which is not that, so an unset budget was being sent.
      const ListingFilters filters = ListingFilters();
      expect(filters.toQuery()['min_price'], 0);
      expect(filters.toQuery()['max_price'], 0);
    });

    test('a budget goes over in whole rupees', () {
      const ListingFilters filters =
          ListingFilters(minPrice: 10000000, maxPrice: 20000000);
      expect(filters.toQuery()['min_price'], 10000000);
      expect(filters.toQuery()['max_price'], 20000000);
      expect(filters.isEmpty, isFalse);
    });
  });
}
