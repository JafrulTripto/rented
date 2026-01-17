import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(
    baseUrl: 'http://localhost:8080',
  ); // Adjust URL if necessary: 10.0.2.2 for Android emulator
});
