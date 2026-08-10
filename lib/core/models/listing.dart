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
        'min_price': minPrice,
        'max_price': maxPrice,
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

/// The signed-in user as the CRM sees them.
class Me extends Equatable {
  const Me({
    required this.email,
    required this.name,
    required this.picture,
    required this.organizationId,
    required this.organizationName,
    required this.vertical,
    required this.role,
    required this.isAdmin,
    required this.canDistributeListings,
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
      role: asString(json['role']),
      isAdmin: json['is_admin'] == true,
      canDistributeListings: json['can_distribute_listings'] == true,
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
  final String role;
  final bool isAdmin;
  final bool canDistributeListings;

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
  List<Object?> get props => <Object?>[email, organizationId, role];
}
