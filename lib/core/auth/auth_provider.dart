import 'package:flutter/foundation.dart';
import '../../services/auth_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final String? username;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.username,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? username,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      username: username ?? this.username,
      error: error,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService) {
    _authService.addListener(_syncFromService);
    _syncFromService();
  }

  final AuthService _authService;
  AuthState _state = const AuthState();

  AuthState get state => _state;
  AuthStatus get status => _state.status;
  String? get username => _state.username;
  String? get error => _state.error;
  AuthService get authService => _authService;

  Future<void> initialize() async {
    await _authService.initialize();
    _syncFromService();
  }

  Future<bool> login(
    String username,
    String password, {
    String? serverUrl,
    String? totpCode,
  }) async {
    final ok = await _authService.login(
      username,
      password,
      serverUrl: serverUrl,
      totpCode: totpCode,
    );
    _syncFromService();
    return ok;
  }

  Future<void> logout() async {
    await _authService.logout();
    _syncFromService();
  }

  void _syncFromService() {
    final nextStatus = _authService.isAuthenticated
        ? AuthStatus.authenticated
        : _authService.isInitialized
            ? AuthStatus.unauthenticated
            : AuthStatus.unknown;
    _state = AuthState(
      status: nextStatus,
      username: _authService.username,
      error: _authService.error,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.removeListener(_syncFromService);
    super.dispose();
  }
}
