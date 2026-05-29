import 'package:flutter/material.dart';

/// Clean immutable Dart class representing the filter state of the application.
class CommonFilter {
  final String searchText;
  final String propertyType;
  final String listingType;
  final String city;
  final String state;
  final RangeValues? priceRange;
  final RangeValues? areaRange;
  final int? bedrooms;
  final int? bathrooms;
  final String furnishing;
  final List<String> amenities;
  final String sortBy;
  final String sortOrder;

  const CommonFilter({
    required this.searchText,
    required this.propertyType,
    required this.listingType,
    required this.city,
    required this.state,
    this.priceRange,
    this.areaRange,
    this.bedrooms,
    this.bathrooms,
    required this.furnishing,
    required this.amenities,
    required this.sortBy,
    required this.sortOrder,
  });

  /// The initial default filter state.
  factory CommonFilter.initial() {
    return const CommonFilter(
      searchText: '',
      propertyType: 'Any',
      listingType: 'Any',
      city: '',
      state: '',
      priceRange: null,
      areaRange: null,
      bedrooms: null,
      bathrooms: null,
      furnishing: 'Any',
      amenities: [],
      sortBy: '',
      sortOrder: 'asc',
    );
  }

  /// Helper to check if any filters are currently active/changed from initial state.
  bool get hasAnyActiveFilter {
    return searchText.isNotEmpty ||
        propertyType != 'Any' ||
        listingType != 'Any' ||
        city.isNotEmpty ||
        state.isNotEmpty ||
        priceRange != null ||
        areaRange != null ||
        bedrooms != null ||
        bathrooms != null ||
        furnishing != 'Any' ||
        amenities.isNotEmpty ||
        sortBy.isNotEmpty;
  }

  /// Create a copy of this filter with only the specified fields changed.
  CommonFilter copyWith({
    String? searchText,
    String? propertyType,
    String? listingType,
    String? city,
    String? state,
    RangeValues? priceRange,
    RangeValues? areaRange,
    int? bedrooms,
    int? bathrooms,
    String? furnishing,
    List<String>? amenities,
    String? sortBy,
    String? sortOrder,
  }) {
    return CommonFilter(
      searchText: searchText ?? this.searchText,
      propertyType: propertyType ?? this.propertyType,
      listingType: listingType ?? this.listingType,
      city: city ?? this.city,
      state: state ?? this.state,
      priceRange: priceRange ?? this.priceRange,
      areaRange: areaRange ?? this.areaRange,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      furnishing: furnishing ?? this.furnishing,
      amenities: amenities ?? this.amenities,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Copy with specific nullable fields set to null explicitly.
  CommonFilter copyWithNull({
    bool priceRange = false,
    bool areaRange = false,
    bool bedrooms = false,
    bool bathrooms = false,
  }) {
    return CommonFilter(
      searchText: searchText,
      propertyType: propertyType,
      listingType: listingType,
      city: city,
      state: state,
      priceRange: priceRange ? null : this.priceRange,
      areaRange: areaRange ? null : this.areaRange,
      bedrooms: bedrooms ? null : this.bedrooms,
      bathrooms: bathrooms ? null : this.bathrooms,
      furnishing: furnishing,
      amenities: amenities,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  /// Serialization to JSON for caching or persistent local storage.
  Map<String, dynamic> toJson() {
    return {
      'searchText': searchText,
      'propertyType': propertyType,
      'listingType': listingType,
      'city': city,
      'state': state,
      'priceRange': priceRange != null ? [priceRange!.start, priceRange!.end] : null,
      'areaRange': areaRange != null ? [areaRange!.start, areaRange!.end] : null,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'furnishing': furnishing,
      'amenities': amenities,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };
  }

  /// Deserialization from JSON.
  factory CommonFilter.fromJson(Map<String, dynamic> json) {
    RangeValues? parseRange(dynamic val) {
      if (val is List && val.length >= 2) {
        return RangeValues(
          (val[0] as num).toDouble(),
          (val[1] as num).toDouble(),
        );
      }
      return null;
    }

    return CommonFilter(
      searchText: json['searchText'] as String? ?? '',
      propertyType: json['propertyType'] as String? ?? 'Any',
      listingType: json['listingType'] as String? ?? 'Any',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      priceRange: parseRange(json['priceRange']),
      areaRange: parseRange(json['areaRange']),
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      furnishing: json['furnishing'] as String? ?? 'Any',
      amenities: (json['amenities'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      sortBy: json['sortBy'] as String? ?? '',
      sortOrder: json['sortOrder'] as String? ?? 'asc',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommonFilter &&
        other.searchText == searchText &&
        other.propertyType == propertyType &&
        other.listingType == listingType &&
        other.city == city &&
        other.state == state &&
        other.priceRange == priceRange &&
        other.areaRange == areaRange &&
        other.bedrooms == bedrooms &&
        other.bathrooms == bathrooms &&
        other.furnishing == furnishing &&
        other.amenities.toString() == amenities.toString() &&
        other.sortBy == sortBy &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode {
    return Object.hash(
      searchText,
      propertyType,
      listingType,
      city,
      state,
      priceRange,
      areaRange,
      bedrooms,
      bathrooms,
      furnishing,
      Object.hashAll(amenities),
      sortBy,
      sortOrder,
    );
  }
}
