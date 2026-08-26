class Property {
  final String id;
  final String name;
  final String location;
  final int price;
  final String type; // rent | buy
  final String propertyKind;
  final List<String> amenities;
  final List<String> images;
  final List<String> videos;
  final String description;
  final DateTime availability;
  final String? facing;
  // Rich API Fields to display details accurately without guessing
  final int? bhk;
  final int? bedrooms;
  final int? bathrooms;
  final int? balconies;
  final int? parking;
  final double? superBuiltUpArea;
  final double? carpetArea;
  final double? builtUpArea;
  final String? furnishing;
  final String? categoryName;
  final String? ownerPhone;
  final String? ownerName;
  final String? listingType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Additional Rich API Fields
  final int? securityDeposit;
  final String? lockInPeriod;
  final String? availableFrom;
  final int? parkingCharges;
  final int? paintingCharges;
  final int? bookingAmount;
  final bool? priceNegotiable;
  final String? propertyHighlights;
  final String? promotionTags;

  // New Mapped Fields
  final double? area;
  final String? areaUnit;
  final List<String> furnishingsList;
  final Map<String, dynamic>? plotDetails;
  final Map<String, dynamic>? pgDetails;
  final Map<String, dynamic>? officeDetails;
  final Map<String, dynamic>? shopDetails;
  final Map<String, dynamic>? warehouseDetails;
  final Map<String, dynamic>? residentialDetails;

  const Property({
    this.facing,
    required this.id,
    required this.name,
    required this.location,
    required this.price,
    required this.type,
    required this.propertyKind,
    required this.amenities,
    required this.images,
    required this.videos,
    required this.description,
    required this.availability,
    this.bhk,
    this.bedrooms,
    this.bathrooms,
    this.balconies,
    this.parking,
    this.superBuiltUpArea,
    this.carpetArea,
    this.builtUpArea,
    this.furnishing,
    this.categoryName,
    this.ownerPhone,
    this.ownerName,
    this.listingType,
    this.createdAt,
    this.updatedAt,
    this.securityDeposit,
    this.lockInPeriod,
    this.availableFrom,
    this.parkingCharges,
    this.paintingCharges,
    this.bookingAmount,
    this.priceNegotiable,
    this.propertyHighlights,
    this.promotionTags,
    this.area,
    this.areaUnit,
    this.furnishingsList = const [],
    this.plotDetails,
    this.pgDetails,
    this.officeDetails,
    this.shopDetails,
    this.warehouseDetails,
    this.residentialDetails,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: (json['id'] ?? '').toString(),
      // API sends 'title', not 'name'
      name: (json['title'] ?? json['name'] ?? '').toString(),
      // API sends 'address', not 'location'
      location: (json['address'] ?? json['location'] ?? '').toString(),
      price: (json['price'] as num?)?.toInt() ?? 0,
      type: (json['type'] ?? 'rent').toString(),
      // API returns property_kind as null; fall back to category.name for type matching
      propertyKind: (() {
        final raw = json['property_kind'] ?? json['propertyKind'];
        if (raw != null && raw.toString().isNotEmpty) return raw.toString();
        // Use category name as the property kind (e.g. 'Builder Floor', 'Flat / Apartment')
        final cat = json['category'];
        if (cat is Map) {
          final catName = cat['name']?.toString() ?? '';
          if (catName.isNotEmpty) return catName;
        }
        return '';
      })(),
      amenities: (() {
        final rawAmenities = json['amenities'];
        final result = <String>[];

        if (rawAmenities is List) {
          result.addAll(
            rawAmenities
                .map((e) {
                  // Amenity object
                  if (e is Map<String, dynamic>) {
                    return (e['name'] ?? e['title'] ?? e['amenity_name'] ?? '')
                        .toString();
                  }

                  // Plain string
                  return e.toString();
                })
                .where((e) => e.trim().isNotEmpty),
          );
        }

        if (json['electricity_included'] == 1 ||
            json['electricity_included'] == true) {
          result.add('Electricity Included');
        }
        if (json['water_included'] == 1 || json['water_included'] == true) {
          result.add('Water Included');
        }
        if (json['gas_included'] == 1 || json['gas_included'] == true) {
          result.add('Gas Included');
        }
        if (json['wifi_included'] == 1 || json['wifi_included'] == true) {
          result.add('WiFi Included');
        }

        return result;
      })(),
      images: (() {
        final rawImages = json['images'];

        if (rawImages is List) {
          return rawImages
              .map((e) {
                // IMAGE OBJECT
                if (e is Map<String, dynamic>) {
                  return (e['image'] ?? e['url'] ?? e['path'] ?? '').toString();
                }

                // STRING URL
                return e.toString();
              })
              .where((e) => e.trim().isNotEmpty)
              .toList();
        }

        return <String>[];
      })(),

      videos: (() {
        final rawVideos = json['videos'];

        if (rawVideos is List) {
          return rawVideos
              .map((e) {
                // VIDEO OBJECT
                if (e is Map<String, dynamic>) {
                  return (e['video'] ?? e['url'] ?? e['path'] ?? '').toString();
                }

                // STRING URL
                return e.toString();
              })
              .where((e) => e.trim().isNotEmpty)
              .toList();
        }

        return <String>[];
      })(),
      description: (json['description'] ?? '').toString(),
      availability:
          DateTime.tryParse((json['availability'] ?? '').toString()) ??
          DateTime.now(),
      facing: json['facing']?.toString(),
      bhk: (() {
        // Try top-level bhk first, then residential_details.bhk_type (e.g. '2 BHK')
        if (json['bhk'] != null) return int.tryParse(json['bhk'].toString());
        final rd = json['residential_details'];
        if (rd is Map) {
          final bhkType = rd['bhk_type']?.toString() ?? '';
          // '2 BHK' → extract the digit
          final match = RegExp(r'(\d+)').firstMatch(bhkType);
          if (match != null) return int.tryParse(match.group(1)!);
          if (rd['bhk'] != null) return int.tryParse(rd['bhk'].toString());
        }
        return null;
      })(),
      bedrooms: json['bedrooms'] != null
          ? int.tryParse(json['bedrooms'].toString())
          : null,
      bathrooms: json['bathrooms'] != null
          ? int.tryParse(json['bathrooms'].toString())
          : null,
      balconies: json['balconies'] != null
          ? int.tryParse(json['balconies'].toString())
          : null,
      parking: json['parking'] != null
          ? int.tryParse(json['parking'].toString())
          : null,
      superBuiltUpArea: json['super_built_up_area'] != null
          ? double.tryParse(json['super_built_up_area'].toString())
          : null,
      carpetArea: json['carpet_area'] != null
          ? double.tryParse(json['carpet_area'].toString())
          : null,
      builtUpArea: json['built_up_area'] != null
          ? double.tryParse(json['built_up_area'].toString())
          : null,
      furnishing: (() {
        final furnishing = json['furnishing'];

        if (furnishing is Map<String, dynamic>) {
          return (furnishing['name'] ?? furnishing['title'] ?? '').toString();
        }

        return (json['furnishing'] ?? json['furnishing_status'])?.toString();
      })(),
      categoryName: json['category'] is Map
          ? (json['category']['name']?.toString())
          : null,
      ownerPhone: json['owner_phone']?.toString(),
      ownerName: json['owner_name']?.toString(),
      listingType: json['listing_type']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      securityDeposit: json['security_deposit'] != null
          ? int.tryParse(json['security_deposit'].toString())
          : null,
      lockInPeriod: json['lock_in_period']?.toString(),
      availableFrom: json['available_from']?.toString(),
      parkingCharges: json['parking_charges'] != null
          ? int.tryParse(json['parking_charges'].toString())
          : null,
      paintingCharges: json['painting_charges'] != null
          ? int.tryParse(json['painting_charges'].toString())
          : null,
      bookingAmount: json['booking_amount'] != null
          ? int.tryParse(json['booking_amount'].toString())
          : null,
      priceNegotiable:
          json['price_negotiable'] == 1 || json['price_negotiable'] == true,
      propertyHighlights: json['property_highlights']?.toString(),
      promotionTags: json['promotion_tags']?.toString(),
      area: json['area'] != null
          ? double.tryParse(json['area'].toString())
          : null,
      areaUnit: json['area_unit']?.toString(),
      furnishingsList: (() {
        final f = json['furnishings'];
        if (f is List) {
          return f
              .map((e) {
                if (e is Map<String, dynamic>) {
                  final quantity = e['pivot']?['quantity'];
                  final name = e['name'];
                  if (quantity != null && name != null) {
                    return '$quantity $name';
                  }
                  return name?.toString() ?? '';
                }
                return e.toString();
              })
              .where((e) => e.isNotEmpty)
              .toList();
        }
        return <String>[];
      })(),
      plotDetails: json['plot_details'] is Map
          ? Map<String, dynamic>.from(json['plot_details'])
          : null,
      pgDetails: json['pg_details'] is Map
          ? Map<String, dynamic>.from(json['pg_details'])
          : null,
      officeDetails: json['office_details'] is Map
          ? Map<String, dynamic>.from(json['office_details'])
          : null,
      shopDetails: json['shop_details'] is Map
          ? Map<String, dynamic>.from(json['shop_details'])
          : null,
      warehouseDetails: json['warehouse_details'] is Map
          ? Map<String, dynamic>.from(json['warehouse_details'])
          : null,
      residentialDetails: json['residential_details'] is Map
          ? Map<String, dynamic>.from(json['residential_details'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'price': price,
    'type': type,
    'property_kind': propertyKind,
    'amenities': amenities,
    'images': images,
    'videos': videos,
    'description': description,
    'availability': availability.toIso8601String(),
    'bhk': bhk,
    'bedrooms': bedrooms,
    'bathrooms': bathrooms,
    'balconies': balconies,
    'parking': parking,
    'super_built_up_area': superBuiltUpArea,
    'carpet_area': carpetArea,
    'built_up_area': builtUpArea,
    'furnishing': furnishing,
    'category_name': categoryName,
    'owner_phone': ownerPhone,
    'owner_name': ownerName,
    'listing_type': listingType,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'security_deposit': securityDeposit,
    'lock_in_period': lockInPeriod,
    'available_from': availableFrom,
    'parking_charges': parkingCharges,
    'painting_charges': paintingCharges,
    'booking_amount': bookingAmount,
    'price_negotiable': priceNegotiable,
    'property_highlights': propertyHighlights,
    'promotion_tags': promotionTags,
    'area': area,
    'area_unit': areaUnit,
    'furnishings': furnishingsList,
    'plot_details': plotDetails,
    'pg_details': pgDetails,
    'office_details': officeDetails,
    'shop_details': shopDetails,
    'warehouse_details': warehouseDetails,
    'residential_details': residentialDetails,
  };
}
