class SavedAddress {
  final String label;
  final double lat;
  final double lng;

  const SavedAddress({
    required this.label,
    required this.lat,
    required this.lng,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
    label: (json['label'] ?? '').toString(),
    lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
    lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {'label': label, 'lat': lat, 'lng': lng};
}
