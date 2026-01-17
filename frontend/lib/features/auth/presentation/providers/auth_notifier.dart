import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/user_model.dart';

// We need to define the provider in lib/features/auth/presentation/providers/auth_provider.dart
// But I'll put the logic here for now or separate it.

class AuthState {
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.token, this.isLoading = false, this.error});

  AuthState copyWith({
    UserModel? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => token != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  static const String _tokenKey = 'auth_token';

  AuthNotifier(this._apiService) : super(AuthState()) {
    _loadToken();
  }

  Future<void> _loadToken() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      _apiService.setToken(token);
      try {
        final user = await _apiService.getProfile();
        state = state.copyWith(user: user, token: token, isLoading: false);
      } catch (e) {
        // Token might be invalid/expired
        state = state.copyWith(isLoading: false, error: 'Session expired');
        await logout();
      }
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.login(email, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, response.token);
      _apiService.setToken(response.token);
      state = state.copyWith(
        user: response.user,
        token: response.token,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.register(email, password, name);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, response.token);
      _apiService.setToken(response.token);
      state = state.copyWith(
        user: response.user,
        token: response.token,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final authentication = await googleUser.authentication;
      final idToken = authentication.idToken;

      if (idToken == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to get Google ID token',
        );
        return;
      }

      final response = await _apiService.signInWithGoogle(idToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, response.token);
      _apiService.setToken(response.token);
      state = state.copyWith(
        user: response.user,
        token: response.token,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _apiService.setToken(null);
    state = AuthState();
  }
}
