class Property {
  final String id;
  final String name;
  final String location;
  final int price;
  final String type; // rent | buy
  final List<String> amenities;
  final List<String> images;
  final List<String> videos;
  final String description;
  final DateTime availability;

  const Property({
    required this.id,
    required this.name,
    required this.location,
    required this.price,
    required this.type,
    required this.amenities,
    required this.images,
    required this.videos,
    required this.description,
    required this.availability,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      price: (json['price'] as num?)?.toInt() ?? 0,
      type: (json['type'] ?? 'rent').toString(),
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
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'price': price,
        'type': type,
        'amenities': amenities,
        'images': images,
        'videos': videos,
        'description': description,
        'availability': availability.toIso8601String(),
      };
}
