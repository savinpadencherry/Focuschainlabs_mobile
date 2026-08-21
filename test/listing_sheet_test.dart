import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focuschainlabs_mobile/core/get.dart';
import 'package:focuschainlabs_mobile/core/models/listing.dart';
import 'package:focuschainlabs_mobile/core/repository/crm_repository.dart';
import 'package:focuschainlabs_mobile/core/theme/app_theme.dart';
import 'package:focuschainlabs_mobile/features/listings/bloc/listings_bloc.dart';
import 'package:focuschainlabs_mobile/features/listings/view/widgets/listing_sheet.dart';
import 'package:focuschainlabs_mobile/features/pipeline/bloc/pipeline_bloc.dart';

/// A property with two photographs — the case that could not be swiped.
final Listing kListing = Listing.fromJson(<String, dynamic>{
  'id': 'l1',
  'title': '4 BHK Luxury Villa in Whitefield',
  'status': 'available',
  'listing_intent': 'sale',
  'property_type': 'Luxury Villa',
  'locality': 'Whitefield',
  'city': 'Bengaluru',
  'price_value': 33000000,
  'price_fmt': '₹3.3 Cr',
  'price_negotiable': true,
  'bhk': '4 BHK',
  'bedrooms': 4,
  'builtup_area_sqft': 2500,
  'images': <dynamic>['gcs:a', 'gcs:b'],
  'photo_count': 2,
  'share_count': 6,
});

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<ListingsBloc>(
            create: (_) => ListingsBloc(repository: app<CrmRepository>()),
          ),
          BlocProvider<PipelineBloc>(
            create: (_) => PipelineBloc(repository: app<CrmRepository>()),
          ),
        ],
        child: Scaffold(body: child),
      ),
    );

void main() {
  setUp(initializeGetIt);

  testWidgets('the property sheet renders without a layout failure',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(ListingSheet(listing: kListing)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('₹3.3 Cr'), findsOneWidget);
    // The title rides the collapsing header, so it is not also printed above
    // the price.
    expect(find.text('4 BHK Luxury Villa in Whitefield'), findsOneWidget);
  });

  testWidgets('the photos can actually be swiped', (WidgetTester tester) async {
    // Inside a FlexibleSpaceBar the gallery rendered and counted its photos but
    // never received the horizontal drag, so a property with two pictures
    // showed one and said "1 / 2" underneath it.
    await tester.pumpWidget(_host(ListingSheet(listing: kListing)));
    await tester.pump();

    expect(find.text('1 / 2'), findsOneWidget);

    // Past the half-page mark, or the view snaps back to where it started —
    // the surface is 800 wide, so -400 is exactly ambiguous.
    final Size page = tester.getSize(find.byType(PageView));
    await tester.drag(find.byType(PageView), Offset(-page.width * 0.8, 0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('2 / 2'), findsOneWidget);
  });
}
