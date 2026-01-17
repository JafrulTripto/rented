import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/providers/api_provider.dart';
import 'auth_notifier.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return AuthNotifier(apiService);
});
