import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_service.dart';
import 'package:frontend/core/providers/api_provider.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/house/data/models/house_model.dart';

class HouseState {
  final List<House> houses;
  final bool isLoading;
  final String? error;

  HouseState({this.houses = const [], this.isLoading = false, this.error});

  HouseState copyWith({List<House>? houses, bool? isLoading, String? error}) {
    return HouseState(
      houses: houses ?? this.houses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HouseNotifier extends StateNotifier<HouseState> {
  final ApiService _apiService;

  HouseNotifier(this._apiService, {bool fetchImmediately = true})
    : super(HouseState()) {
    if (fetchImmediately) {
      fetchHouses();
    }
  }

  Future<void> fetchHouses() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final houses = await _apiService.getHouses();
      state = state.copyWith(houses: houses, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addHouse(String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final house = await _apiService.createHouse(name);
      state = state.copyWith(
        houses: [...state.houses, house],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addFlat(
    String houseId,
    String number,
    double basicRent,
    double gasBill,
    double utilityBill,
    double waterCharges,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final flat = await _apiService.createFlat(
        houseId,
        number,
        basicRent,
        gasBill,
        utilityBill,
        waterCharges,
      );
      final updatedHouses = state.houses.map((h) {
        if (h.id == houseId) {
          return House(
            id: h.id,
            userId: h.userId,
            name: h.name,
            flats: [...h.flats, flat],
          );
        }
        return h;
      }).toList();
      state = state.copyWith(houses: updatedHouses, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final houseProvider = StateNotifierProvider<HouseNotifier, HouseState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final authState = ref.watch(authProvider);

  if (!authState.isAuthenticated) {
    return HouseNotifier(apiService, fetchImmediately: false);
  }

  return HouseNotifier(apiService);
});
