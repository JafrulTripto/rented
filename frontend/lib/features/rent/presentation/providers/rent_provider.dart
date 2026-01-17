import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_service.dart';
import 'package:frontend/core/providers/api_provider.dart';
import 'package:frontend/features/rent/data/models/rent_payment_model.dart';
import 'package:frontend/features/dashboard/presentation/providers/dashboard_provider.dart';

final rentListProvider =
    StateNotifierProvider.family<
      RentListNotifier,
      AsyncValue<List<RentPayment>>,
      String
    >((ref, tenantId) {
      return RentListNotifier(ref.watch(apiServiceProvider), tenantId, ref);
    });

class RentListNotifier extends StateNotifier<AsyncValue<List<RentPayment>>> {
  final ApiService _apiService;
  final String _tenantId;
  final Ref _ref;

  RentListNotifier(this._apiService, this._tenantId, this._ref)
    : super(const AsyncValue.loading()) {
    fetchRents();
  }

  Future<void> fetchRents() async {
    state = const AsyncValue.loading();
    try {
      final rents = await _apiService.getTenantRents(_tenantId);
      state = AsyncValue.data(rents);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRent(RentPayment rent) async {
    try {
      await _apiService.createRent(rent);
      fetchRents();
      _ref.invalidate(dashboardProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
