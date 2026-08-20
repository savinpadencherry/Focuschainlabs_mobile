import 'package:equatable/equatable.dart';

import 'pipeline.dart' show asDouble, asInt, asMap, asString, asStrings;

/// A property in the org's inventory.
///
/// Prices arrive as both a number and a formatted string. The client sorts and
/// filters on [priceValue] and prints [priceFmt] — parsing "₹3.2 Cr" back into
/// a number is the round trip that turns 3.2 Cr into ₹3.
class Listing extends Equatable {
  const Listing({
    required this.id,
    required this.title,
    required this.status,
    required this.listingIntent,
    required this.propertyType,
    required this.locality,
    required this.city,
    required this.price,
    required this.priceValue,
    required this.priceFmt,
    required this.priceNegotiable,
    required this.bhk,
    required this.bedrooms,
    required this.bathrooms,
    required this.builtupAreaSqft,
    required this.carpetAreaSqft,
    required this.furnishing,
    required this.facing,
    required this.floorNo,
    required this.totalFloors,
    required this.possessionStatus,
    required this.ownership,
    required this.reraId,
    required this.amenities,
    required this.description,
    required this.images,
    required this.ownerName,
    required this.ownerPhone,
    required this.listingAgent,
    required this.assignedTo,
    required this.shareCount,
    required this.photoCount,
  });

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
        id: asString(json['id']),
        title: asString(json['title']),
        status: asString(json['status']),
        listingIntent: asString(json['listing_intent']),
        propertyType: asString(json['property_type']),
        locality: asString(json['locality']),
        city: asString(json['city']),
        price: asString(json['price']),
        priceValue: asDouble(json['price_value']),
        priceFmt: asString(json['price_fmt']),
        priceNegotiable: json['price_negotiable'] == true,
        bhk: asString(json['bhk']),
        bedrooms: asInt(json['bedrooms']),
        bathrooms: asInt(json['bathrooms']),
        builtupAreaSqft: asInt(json['builtup_area_sqft']),
        carpetAreaSqft: asInt(json['carpet_area_sqft']),
        furnishing: asString(json['furnishing']),
        facing: asString(json['facing']),
        floorNo: asInt(json['floor_no']),
        totalFloors: asInt(json['total_floors']),
        possessionStatus: asString(json['possession_status']),
        ownership: asString(json['ownership']),
        reraId: asString(json['rera_id']),
        amenities: asStrings(json['amenities']),
        description: asString(json['description']),
        images: asStrings(json['images']),
        ownerName: asString(json['owner_name']),
        ownerPhone: asString(json['owner_phone']),
        listingAgent: asString(json['listing_agent']),
        assignedTo: asStrings(json['assigned_to']),
        shareCount: asInt(json['share_count']),
        // An older API sends no count. Falling back to the reference list is
        // right there and wrong nowhere: a dead reference costs one blank
        // gallery page, and refusing to show any gallery costs all of them.
        photoCount: json.containsKey('photo_count')
            ? asInt(json['photo_count'])
            : asStrings(json['images']).length,
      );

  final String id;
  final String title;
  final String status;
  final String listingIntent;
  final String propertyType;
  final String locality;
  final String city;

  /// As typed ("3.3 Cr"). [priceValue] is the parsed number search filters on,
  /// and [priceFmt] is what to print — this one exists so an edit form can
  /// show what someone actually wrote.
  final String price;
  final double priceValue;
  final String priceFmt;
  final bool priceNegotiable;
  final String bhk;
  final int bedrooms;
  final int bathrooms;
  final int builtupAreaSqft;
  final int carpetAreaSqft;
  final String furnishing;
  final String facing;
  final int floorNo;
  final int totalFloors;
  final String possessionStatus;
  final String ownership;
  final String reraId;
  final List<String> amenities;
  final String description;
  final List<String> images;
  final String ownerName;
  final String ownerPhone;
  final String listingAgent;
  final List<String> assignedTo;
  final int shareCount;

  /// How many photos `/api/listings/{id}/photo/{n}` will serve.
  final int photoCount;

  bool get hasPhotos => photoCount > 0;

  String get where => <String>[locality, city]
      .where((String s) => s.isNotEmpty)
      .toSet()
      .join(', ');

  bool get isAvailable => status.toLowerCase() == 'available';

  /// Nobody owes the seller a call yet — the signal the distribution queue exists for.
  bool get isUnassigned => assignedTo.isEmpty;

  String get carpetAreaLabel => carpetAreaSqft > 0 ? '$carpetAreaSqft sqft' : '';

  /// "7 of 14", or just "7" when the building's height is unrecorded.
  String get floorLabel {
    if (floorNo <= 0) return '';
    return totalFloors > 0 ? '$floorNo of $totalFloors' : '$floorNo';
  }

  /// The short facts strip under the title: "3 BHK · 1,450 sqft · Semi-furnished".
  List<String> get facts => <String>[
        if (bhk.isNotEmpty) bhk,
        if (builtupAreaSqft > 0) '$builtupAreaSqft sqft',
        if (furnishing.isNotEmpty) furnishing,
        if (facing.isNotEmpty) '$facing facing',
      ];

  @override
  List<Object?> get props => <Object?>[id, status, priceValue, shareCount];
}

/// One page of search results.
class ListingResults extends Equatable {
  const ListingResults({
    required this.total,
    required this.listings,
  });

  factory ListingResults.fromJson(Map<String, dynamic> json) => ListingResults(
        total: asInt(json['total']),
        listings: (json['listings'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(Listing.fromJson)
            .toList(),
      );

  static const ListingResults empty =
      ListingResults(total: 0, listings: <Listing>[]);

  /// How many properties exist in the org at all, before filters. Lets an empty
  /// result say "no match for this search" rather than "no inventory".
  final int total;
  final List<Listing> listings;

  @override
  List<Object?> get props => <Object?>[total, listings];
}

/// The filters a search is running under.
///
/// Kept as an object so the UI can restate the parsed query as removable chips —
/// a rep verifies and corrects in one tap instead of retyping the search.
class ListingFilters extends Equatable {
  const ListingFilters({
    this.query = '',
    this.locality = '',
    this.propertyType = '',
    this.bhk = '',
    this.status = '',
    this.minPrice = 0,
    this.maxPrice = 0,
  });

  final String query;
  final String locality;
  final String propertyType;
  final String bhk;
  final String status;
  final double minPrice;
  final double maxPrice;

  bool get isEmpty =>
      query.isEmpty &&
      locality.isEmpty &&
      propertyType.isEmpty &&
      bhk.isEmpty &&
      status.isEmpty &&
      minPrice == 0 &&
      maxPrice == 0;

  ListingFilters copyWith({
    String? query,
    String? locality,
    String? propertyType,
    String? bhk,
    String? status,
    double? minPrice,
    double? maxPrice,
  }) =>
      ListingFilters(
        query: query ?? this.query,
        locality: locality ?? this.locality,
        propertyType: propertyType ?? this.propertyType,
        bhk: bhk ?? this.bhk,
        status: status ?? this.status,
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
      );

  Map<String, dynamic> toQuery() => <String, dynamic>{
        'q': query,
        'locality': locality,
        'property_type': propertyType,
        'bhk': bhk,
        'status': status,
        // Whole rupees. A double stringifies as "40000000.0", and the API
        // client drops a filter whose value is exactly '0' — "0.0" is not, so
        // an unset budget was being sent as a filter.
        'min_price': minPrice.round(),
        'max_price': maxPrice.round(),
      };

  @override
  List<Object?> get props =>
      <Object?>[query, locality, propertyType, bhk, status, minPrice, maxPrice];
}

/// One of the canned questions about a property.
///
/// A closed list, not free text: every answer is grounded in a query the
/// server runs, and a question outside the list would have nothing to ground
/// it in.
class ListingQuestion extends Equatable {
  const ListingQuestion({required this.id, required this.label});

  factory ListingQuestion.fromJson(Map<String, dynamic> json) =>
      ListingQuestion(
        id: asString(json['id']),
        label: asString(json['label']),
      );

  final String id;
  final String label;

  @override
  List<Object?> get props => <Object?>[id, label];
}

/// What the signed-in user may do, decided by the server and never guessed.
///
/// The app used to build a user at sign-in with the organisation hard-coded to
/// `org-fcl` and the role to admin — right for one tenant and one person,
/// wrong for everyone else. Every affordance now reads from here, and the API
/// enforces the same rules independently, so a stale copy on a phone cannot
/// become access it does not have.
class Access extends Equatable {
  const Access({
    this.scope = 'own',
    this.canEditLeads = true,
    this.canEditListings = true,
    this.canDistributeListings = false,
    this.canManageMembers = false,
    this.canViewPrivateNotes = false,
    this.editableLeadFields = const <String>[],
    this.editableListingFields = const <String>[],
  });

  factory Access.fromJson(Map<String, dynamic> json) => Access(
        scope: asString(json['scope']).isEmpty ? 'own' : asString(json['scope']),
        canEditLeads: json['can_edit_leads'] != false,
        canEditListings: json['can_edit_listings'] != false,
        canDistributeListings: json['can_distribute_listings'] == true,
        canManageMembers: json['can_manage_members'] == true,
        canViewPrivateNotes: json['can_view_private_notes'] == true,
        editableLeadFields: asStrings(json['editable_lead_fields']),
        editableListingFields: asStrings(json['editable_listing_fields']),
      );

  /// Before `/api/me` has answered, and for a server too old to send this.
  /// Deliberately the app's previous behaviour: the server is the gate, so
  /// guessing generously here costs a rejected write, and guessing meanly
  /// costs a rep a button they are entitled to.
  static const Access unknown = Access();

  /// `all` · `own` · `aggregate` — which leads this user may see.
  final String scope;
  final bool canEditLeads;
  final bool canEditListings;
  final bool canDistributeListings;
  final bool canManageMembers;
  final bool canViewPrivateNotes;

  /// The API's own edit allowlists. A form built from these cannot offer a
  /// field the server will reject; empty means the server did not say, and the
  /// caller should fall back to its built-in list.
  final List<String> editableLeadFields;
  final List<String> editableListingFields;

  /// A manager reads counts and totals and opens no individual lead. Their
  /// board is empty *by design*, which is a different screen from "we could
  /// not load your leads".
  bool get seesAggregatesOnly => scope == 'aggregate';

  bool get seesEveryLead => scope == 'all';

  String get scopeLabel => switch (scope) {
        'all' => 'Every lead in the workspace',
        'aggregate' => 'Totals only — no individual leads',
        _ => 'The leads you own',
      };

  bool canEditLeadField(String field) =>
      editableLeadFields.isEmpty || editableLeadFields.contains(field);

  @override
  List<Object?> get props => <Object?>[
        scope,
        canEditLeads,
        canEditListings,
        canDistributeListings,
        canManageMembers,
        canViewPrivateNotes,
        editableLeadFields,
        editableListingFields,
      ];
}

/// The signed-in user as the CRM sees them.
class Me extends Equatable {
  const Me({
    required this.email,
    required this.name,
    required this.picture,
    required this.organizationId,
    required this.organizationName,
    required this.vertical,
    required this.dialCode,
    required this.role,
    required this.isAdmin,
    required this.canDistributeListings,
    required this.timezone,
    required this.access,
  });

  factory Me.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> org = asMap(json['organization']);
    return Me(
      email: asString(json['email']),
      name: asString(json['name']),
      picture: asString(json['picture']),
      organizationId: asString(json['organization_id']),
      organizationName: asString(org['name']),
      vertical: asString(org['vertical']),
      dialCode: asString(org['dial_code']).isNotEmpty
          ? asString(org['dial_code'])
          : '91',
      role: asString(json['role']),
      isAdmin: json['is_admin'] == true,
      canDistributeListings: json['can_distribute_listings'] == true,
      timezone: asString(org['timezone']),
      access: json.containsKey('access')
          ? Access.fromJson(asMap(json['access']))
          : Access.unknown,
    );
  }

  final String email;
  final String name;
  final String picture;
  final String organizationId;
  final String organizationName;

  /// `real_estate` or `b2b_saas`. Decides whether property inventory is a
  /// thing this tenant has at all.
  final String vertical;

  /// The country calling code for this workspace's local phone numbers.
  /// Needed to turn '8422978854' into a number WhatsApp accepts; which country
  /// that is belongs to the tenant, not to the client.
  final String dialCode;
  final String role;
  final bool isAdmin;
  final bool canDistributeListings;

  /// The workspace's own timezone. A follow-up "due today" is due today
  /// where the office is, not where the phone happens to be roaming.
  final String timezone;

  /// Everything this user may do, as the server decides it.
  final Access access;

  /// Whether this tenant deals in property.
  ///
  /// A B2B SaaS tenant has no inventory, so the Listings surface is not a
  /// smaller version of itself for them — it is a surface about someone
  /// else's business.
  bool get isRealEstate => vertical == 'real_estate';

  String get initials {
    final List<String> parts = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((String p) => p.isEmpty);
    if (parts.isEmpty) return email.isEmpty ? '?' : email[0].toUpperCase();
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  List<Object?> get props => <Object?>[email, organizationId, role, access];
}
