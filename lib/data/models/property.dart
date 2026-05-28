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

  const Property({
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
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      price: (json['price'] as num?)?.toInt() ?? 0,
      type: (json['type'] ?? 'rent').toString(),
      propertyKind: (json['property_kind'] ?? json['propertyKind'] ?? '').toString(),
      amenities:
          (json['amenities'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      images:
          (json['images'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      videos:
          (json['videos'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      description: (json['description'] ?? '').toString(),
      availability:
          DateTime.tryParse((json['availability'] ?? '').toString()) ??
          DateTime.now(),
      bhk: json['bhk'] != null ? int.tryParse(json['bhk'].toString()) : null,
      bedrooms: json['bedrooms'] != null ? int.tryParse(json['bedrooms'].toString()) : null,
      bathrooms: json['bathrooms'] != null ? int.tryParse(json['bathrooms'].toString()) : null,
      balconies: json['balconies'] != null ? int.tryParse(json['balconies'].toString()) : null,
      parking: json['parking'] != null ? int.tryParse(json['parking'].toString()) : null,
      superBuiltUpArea: json['super_built_up_area'] != null ? double.tryParse(json['super_built_up_area'].toString()) : null,
      carpetArea: json['carpet_area'] != null ? double.tryParse(json['carpet_area'].toString()) : null,
      builtUpArea: json['built_up_area'] != null ? double.tryParse(json['built_up_area'].toString()) : null,
      furnishing: json['furnishing']?.toString(),
      categoryName: json['category'] is Map ? (json['category']['name']?.toString()) : null,
      ownerPhone: json['owner_phone']?.toString(),
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
      };
}
