import '../../../data/models/property.dart';

class PropertyListArgs {
  final String title;
  final List<Property> items;

  const PropertyListArgs({
    required this.title,
    required this.items,
  });
}

