import 'package:flutter/material.dart';

class SearchArgs {
  final String mode;
  final RangeValues budget;
  final String propertyType;
  final List<String> amenities;
  final String locationQuery;
  final String sortBy;

  /// True when navigating from a quick-action tab (Rent, Buy, PG, etc.).
  /// Uses nearby/fetchAll + client-side filter instead of the broken
  /// /properties?type= endpoint.
  final bool fromTab;

  const SearchArgs({
    required this.mode,
    required this.budget,
    required this.propertyType,
    required this.amenities,
    required this.locationQuery,
    this.sortBy = '',
    this.fromTab = false,
  });
}
