class Lead {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String type;
  final String propertyType;
  final String city;
  final String state;
  final String pincode;
  final String status;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Lead({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.type,
    required this.propertyType,
    required this.city,
    required this.state,
    required this.pincode,
    required this.status,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime _parseDate(dynamic v) =>
      DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: json['email']?.toString(),
      type: (json['type'] ?? '').toString(),
      propertyType: (json['property_type'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      pincode: (json['pincode'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }
}

class LeadPage {
  final int currentPage;
  final int lastPage;
  final int total;
  final List<Lead> data;

  const LeadPage({
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.data,
  });

  factory LeadPage.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

    final dataRaw = json['data'];
    final leads = (dataRaw is List)
        ? dataRaw
              .whereType<Map>()
              .map((e) => Lead.fromJson(e.cast<String, dynamic>()))
              .toList(growable: false)
        : const <Lead>[];

    return LeadPage(
      currentPage: parseInt(json['current_page']),
      lastPage: parseInt(json['last_page']),
      total: parseInt(json['total']),
      data: leads,
    );
  }
}
