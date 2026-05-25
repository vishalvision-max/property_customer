import '../models/lead.dart';
import '../services/lead_service.dart';

class LeadRepository {
  final LeadService _service;

  LeadRepository(this._service);

  Future<LeadPage> fetchMyLeads({required String token, int page = 1}) =>
      _service.fetchMyLeads(token: token, page: page);

  Future<void> updateStatus({
    required String token,
    required String leadId,
    required String status,
  }) => _service.updateLeadStatus(token: token, leadId: leadId, status: status);

  Future<void> create({
    String? token,
    required String name,
    required String phone,
    String? email,
    required String type,
    required String propertyType,
    required String city,
    required String state,
    required String pincode,
    String? address,
    String? budgetMin,
    String? budgetMax,
    String? message,
    String? source,
    String? utmSource,
    String? utmMedium,
    String? utmCampaign,
  }) => _service.createLead(
    token: token,
    name: name,
    phone: phone,
    email: email,
    type: type,
    propertyType: propertyType,
    city: city,
    state: state,
    pincode: pincode,
    address: address,
    budgetMin: budgetMin,
    budgetMax: budgetMax,
    message: message,
    source: source,
    utmSource: utmSource,
    utmMedium: utmMedium,
    utmCampaign: utmCampaign,
  );

  Future<void> createBuyerLead({
    required String token,
    required String name,
    required String phone,
    required String email,
    required String message,
    required String type,
    required int propertyId,
  }) => _service.createBuyerLead(
    token: token,
    name: name,
    phone: phone,
    email: email,
    message: message,
    type: type,
    propertyId: propertyId,
  );
}
