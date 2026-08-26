import 'package:property_customer/data/models/property.dart';

class ScheduledVisit {
  final String id;
  final String propertyId;
  final String userId;
  final String scheduledDate;
  final String scheduledTime;
  final String status;
  final Property? property;

  const ScheduledVisit({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.status,
    this.property,
  });

  factory ScheduledVisit.fromJson(Map<String, dynamic> json) {
    return ScheduledVisit(
      id: (json['id'] ?? '').toString(),
      propertyId: (json['property_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      scheduledDate: (json['scheduled_date'] ?? '').toString(),
      scheduledTime: (json['scheduled_time'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      property: json['property'] != null
          ? Property.fromJson(json['property'])
          : null,
    );
  }
}
