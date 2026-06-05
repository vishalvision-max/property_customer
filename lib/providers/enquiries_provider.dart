import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/lead.dart';
import 'app_providers.dart';
import 'auth_provider.dart';

part 'enquiries_provider.g.dart';

@riverpod
class EnquiriesNotifier extends _$EnquiriesNotifier {
  @override
  FutureOr<List<Lead>> build() async {
    return _fetchEnquiries();
  }

  Future<List<Lead>> _fetchEnquiries() async {
    final token = ref.read(authProvider).user?.token;
    if (token == null || token.isEmpty) {
      return [];
    }
    final leadService = ref.read(leadRepositoryProvider);
    return await leadService.fetchEnquiries(token: token);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchEnquiries());
  }
}
