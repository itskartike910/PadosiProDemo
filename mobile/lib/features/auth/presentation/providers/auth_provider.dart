import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/storage/token_storage.dart';

// ── User model (simple inline, no code-gen needed for this small model) ──────

class UserModel {
  final String id;
  final String email;
  final String? phoneNumber;
  final String? name;
  final String? address;
  final String? society;
  final String? flatUnit;
  final String? gateNotes;
  final String? businessName;
  final bool isEmailVerified;
  final bool isProfileComplete;

  const UserModel({
    required this.id,
    required this.email,
    this.phoneNumber,
    this.name,
    this.address,
    this.society,
    this.flatUnit,
    this.gateNotes,
    this.businessName,
    required this.isEmailVerified,
    required this.isProfileComplete,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        phoneNumber: json['phone_number'] as String?,
        name: json['name'] as String?,
        address: json['address'] as String?,
        society: json['society'] as String?,
        flatUnit: json['flat_unit'] as String?,
        gateNotes: json['gate_notes'] as String?,
        businessName: json['business_name'] as String?,
        isEmailVerified: json['is_email_verified'] as bool? ?? false,
        isProfileComplete: json['is_profile_complete'] as bool? ?? false,
      );
}

// ── Auth State ────────────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState { const AuthInitial(); }
class AuthLoading extends AuthState { const AuthLoading(); }

class AuthUnauthenticated extends AuthState {
  final String? error;
  const AuthUnauthenticated({this.error});
}

/// OTP has been sent to email — show OTP screen
class AuthOtpSent extends AuthState {
  final String email;
  final String phoneNumber;
  final String? error;  // non-null when OTP verification failed
  const AuthOtpSent({
    required this.email,
    required this.phoneNumber,
    this.error,
  });
}

/// OTP verified — pending success animation
class AuthSuccessPending extends AuthState {
  final UserModel user;
  const AuthSuccessPending(this.user);
}

/// OTP verified — profile setup required
class AuthProfileSetupRequired extends AuthState {
  final UserModel user;
  const AuthProfileSetupRequired(this.user);
}

/// Fully authenticated
class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
}

// ── Auth Notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  // Track last OTP destination so we can re-emit AuthOtpSent on verify error
  String _otpEmail = '';
  String _otpPhone = '';

  AuthNotifier(this._apiClient, this._tokenStorage) : super(const AuthInitial()) {
    checkAuthStatus();
  }

  // ── Session restoration ──────────────────────────────────────────────────

  Future<void> checkAuthStatus() async {
    state = const AuthLoading();
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        state = const AuthUnauthenticated();
        return;
      }
      final response = await _apiClient.get('/auth/me');
      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data['data']);
        if (user.isProfileComplete) {
          state = AuthAuthenticated(user);
        } else {
          state = AuthProfileSetupRequired(user);
        }
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      _log('checkAuthStatus error: $e');
      state = const AuthUnauthenticated();
    }
  }

  // ── Register (Email + Password) ──────────────────────────────────────────

  Future<void> register({
    required String email,
    required String password,
    required String confirmPassword,
    String? phoneNumber,
  }) async {
    _otpEmail = email;
    _otpPhone = phoneNumber ?? '';
    state = const AuthLoading();
    try {
      final response = await _apiClient.post('/auth/register', data: {
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
        'phone_number': (phoneNumber != null && phoneNumber.trim().isNotEmpty) ? phoneNumber : null,
      });
      if (response.statusCode == 201 || response.statusCode == 200) {
        state = AuthOtpSent(email: email, phoneNumber: phoneNumber ?? '');
      } else {
        final msg = _extractError(response.data);
        state = AuthUnauthenticated(error: msg);
      }
    } catch (e) {
      state = AuthUnauthenticated(error: _dioError(e));
    }
  }

  // ── Login (Email + Password) ─────────────────────────────────────────────

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final response = await _apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _tokenStorage.saveTokens(
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String,
        );
        final user = UserModel.fromJson(data['user']);
        if (user.isProfileComplete) {
          state = AuthAuthenticated(user);
        } else {
          state = AuthProfileSetupRequired(user);
        }
      } else {
        final errCode = response.data?['error']?['code'];
        final msg = _extractError(response.data);
        if (errCode == 'EMAIL_NOT_VERIFIED') {
          _otpEmail = email;
          state = AuthOtpSent(email: email, phoneNumber: '', error: msg);
        } else {
          state = AuthUnauthenticated(error: msg);
        }
      }
    } catch (e) {
      // Check if dio error response was 403 EMAIL_NOT_VERIFIED
      try {
        final dynamic err = e;
        final resp = err.response;
        if (resp != null && resp.data?['error']?['code'] == 'EMAIL_NOT_VERIFIED') {
          _otpEmail = email;
          state = AuthOtpSent(
            email: email,
            phoneNumber: '',
            error: resp.data['error']['message'] ?? 'Please verify your email.',
          );
          return;
        }
      } catch (_) {}
      state = AuthUnauthenticated(error: _dioError(e));
    }
  }

  // ── Send OTP (Legacy / Resend) ───────────────────────────────────────────

  Future<void> sendOtp({required String phone, required String email}) async {
    _otpEmail = email;
    _otpPhone = phone;
    state = const AuthLoading();
    try {
      final response = await _apiClient.post('/auth/send-otp', data: {
        'phone_number': phone,
        'email': email,
      });
      if (response.statusCode == 200) {
        state = AuthOtpSent(email: email, phoneNumber: phone);
      } else {
        final msg = _extractError(response.data);
        state = AuthUnauthenticated(error: msg);
      }
    } catch (e) {
      state = AuthUnauthenticated(error: _dioError(e));
    }
  }

  // ── Verify OTP ───────────────────────────────────────────────────────────

  Future<void> verifyOtp({required String email, required String otp}) async {
    state = const AuthLoading();
    try {
      final response = await _apiClient.post('/auth/verify-otp', data: {
        'email': email,
        'otp': otp,
      });
      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _tokenStorage.saveTokens(
          accessToken:  data['access_token']  as String,
          refreshToken: data['refresh_token'] as String,
        );
        final user = UserModel.fromJson(data['user']);
        state = AuthSuccessPending(user);
      } else {
        final msg = _extractError(response.data);
        // Stay on OTP page — emit AuthOtpSent with error, NOT AuthUnauthenticated
        state = AuthOtpSent(
          email: _otpEmail.isNotEmpty ? _otpEmail : email,
          phoneNumber: _otpPhone,
          error: msg,
        );
      }
    } catch (e) {
      state = AuthOtpSent(
        email: _otpEmail.isNotEmpty ? _otpEmail : email,
        phoneNumber: _otpPhone,
        error: _dioError(e),
      );
    }
  }

  // ── Finalize OTP verification after animation completes ──────────────────

  void finalizeSuccess(UserModel user) {
    if (user.isProfileComplete) {
      state = AuthAuthenticated(user);
    } else {
      state = AuthProfileSetupRequired(user);
    }
  }

  // ── Profile setup complete ───────────────────────────────────────────────

  void profileCompleted(UserModel user) {
    state = AuthAuthenticated(user);
  }

  // ── Reset to unauthenticated (e.g. user pressed Back on OTP page) ────────

  void resetToUnauthenticated() {
    state = const AuthUnauthenticated();
  }

  // ── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    state = const AuthLoading();
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken != null) {
        await _apiClient.post('/auth/logout', data: {'refresh_token': refreshToken});
      }
    } catch (_) {}
    await _tokenStorage.clearTokens();
    state = const AuthUnauthenticated();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _extractError(dynamic data) {
    try {
      return data['error']['message'] as String? ?? 'Something went wrong.';
    } catch (_) {
      return 'Something went wrong.';
    }
  }

  String _dioError(Object e) {
    try {
      // DioException
      final dynamic err = e;
      final respData = err.response?.data;
      if (respData != null) return _extractError(respData);
      return err.message?.toString() ?? e.toString();
    } catch (_) {
      return e.toString();
    }
  }

  void _log(String msg) {
    if (kDebugMode) debugPrint('[AuthNotifier] $msg');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient    = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthNotifier(apiClient, tokenStorage);
});
