import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class SessionState {
  final AppUser? user;
  final bool isLoading;
  final String? error;

  const SessionState({this.user, this.isLoading = false, this.error});

  bool get isLoggedIn => user != null;

  SessionState copyWith({AppUser? user, bool? isLoading, String? error, bool clearUser = false}) {
    return SessionState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier() : super(const SessionState(isLoading: true)) {
    _restore();
  }

  final AuthService _authService = AuthService();

  Future<void> _restore() async {
    final user = await _authService.restoreSession();
    state = SessionState(user: user, isLoading: false);
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.login(email: email, password: password);
      state = SessionState(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String role = 'guest',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      state = SessionState(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const SessionState(user: null, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// يحدّث بيانات المستخدم محلياً بعد نجاح تعديل الملف الشخصي (بدون تسجيل دخول من جديد)
  void updateLocalUser(AppUser user) {
    state = state.copyWith(user: user);
  }

  Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? currentPassword,
    String? newPassword,
  }) async {
    final user = await _authService.updateProfile(
      fullName: fullName,
      phone: phone,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    updateLocalUser(user);
  }
  Future<void> updateAvatar({String? filePath, bool remove = false}) async {
    final user = await _authService.updateAvatar(filePath: filePath, remove: remove);
    updateLocalUser(user);
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>(
  (ref) => SessionNotifier(),
);
