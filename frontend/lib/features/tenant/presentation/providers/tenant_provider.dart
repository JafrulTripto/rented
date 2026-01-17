import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_service.dart';
import 'package:frontend/core/providers/api_provider.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:frontend/features/tenant/data/models/tenant_model.dart';

class TenantState {
  final List<Tenant> tenants;
  final bool isLoading;
  final String? error;

  TenantState({this.tenants = const [], this.isLoading = false, this.error});

  TenantState copyWith({
    List<Tenant>? tenants,
    bool? isLoading,
    String? error,
  }) {
    return TenantState(
      tenants: tenants ?? this.tenants,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TenantNotifier extends StateNotifier<TenantState> {
  final ApiService _apiService;
  final Ref _ref;

  TenantNotifier(this._apiService, this._ref, {bool fetchImmediately = true})
    : super(TenantState()) {
    if (fetchImmediately) {
      fetchTenants();
    }
  }

  Future<void> fetchTenants() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tenants = await _apiService.getTenants();
      state = state.copyWith(tenants: tenants, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addTenant({
    required String name,
    required String phone,
    required String houseId,
    required String flatId,
    required String nidNumber,
    required double advanceAmount,
    required DateTime joinDate,
    File? nidFront,
    File? nidBack,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tenant = await _apiService.createTenant(
        name: name,
        phone: phone,
        houseId: houseId,
        flatId: flatId,
        nidNumber: nidNumber,
        advanceAmount: advanceAmount,
        joinDate: joinDate,
        nidFront: nidFront,
        nidBack: nidBack,
      );
      state = state.copyWith(
        tenants: [...state.tenants, tenant],
        isLoading: false,
      );
      // Refresh Dashboard
      _ref.invalidate(dashboardProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleTenantStatus(String tenantId, bool isActive) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedTenant = await _apiService.updateTenantStatus(
        tenantId,
        isActive,
      );
      state = state.copyWith(
        tenants: [
          for (final t in state.tenants)
            if (t.id == tenantId) updatedTenant else t,
        ],
        isLoading: false,
      );
      // Refresh Dashboard
      _ref.invalidate(dashboardProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final tenantProvider = StateNotifierProvider<TenantNotifier, TenantState>((
  ref,
) {
  final apiService = ref.read(apiServiceProvider);
  final authState = ref.watch(authProvider);

  // If not authenticated, return an empty state or a notifier that does nothing
  if (!authState.isAuthenticated) {
    return TenantNotifier(apiService, ref, fetchImmediately: false);
  }

  return TenantNotifier(apiService, ref);
});
