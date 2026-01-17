import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/config.dart';
import 'package:frontend/core/network/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(baseUrl: Config.apiBaseUrl);
});
