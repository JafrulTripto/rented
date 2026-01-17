import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/providers/api_provider.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/dashboard_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardStats>>((ref) {
      final apiService = ref.watch(apiServiceProvider);
      final authState = ref.watch(authProvider);
      return DashboardNotifier(apiService, authState.user?.id);
    });

class DashboardNotifier extends StateNotifier<AsyncValue<DashboardStats>> {
  final ApiService _apiService;
  final String? _userId;

  DashboardNotifier(this._apiService, this._userId)
    : super(const AsyncValue.loading()) {
    if (_userId != null) {
      fetchStats();
    }
  }

  Future<void> fetchStats() async {
    if (_userId == null) return;
    try {
      state = const AsyncValue.loading();
      final data = await _apiService.getDashboardStats(_userId!);
      final stats = DashboardStats.fromMap(data);
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
