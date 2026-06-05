import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/scheduled_visit.dart';
import 'app_providers.dart';
import 'auth_provider.dart';

part 'scheduled_visits_provider.g.dart';

@riverpod
class ScheduledVisitsNotifier extends _$ScheduledVisitsNotifier {
  @override
  FutureOr<List<ScheduledVisit>> build() async {
    return _fetchVisits();
  }

  Future<List<ScheduledVisit>> _fetchVisits() async {
    final token = ref.read(authProvider).user?.token;
    if (token == null || token.isEmpty) {
      return [];
    }
    final propertyService = ref.read(propertyServiceProvider);
    return await propertyService.fetchScheduledVisits(token);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchVisits());
  }
}
