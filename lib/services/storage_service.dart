import 'package:shared_preferences/shared_preferences.dart';

/// Handles local persistence for the OTP flow and session state.
///
/// NOTE ON SECURITY: storing the plaintext OTP on-device is implemented
/// here to satisfy the requirement of caching the OTP locally for
/// comparison. In a production system the OTP should never be exposed to
/// the client at all — verification should happen entirely server-side.
/// This app also calls [ApiService.verifyOtp] as the authoritative check;
/// treat the local copy as a convenience layer only, not as security.
class StorageService {
  static const _keyPhone = 'servizipro_phone';
  static const _keyOtp = 'servizipro_otp';
  static const _keyRequestId = 'servizipro_request_id';
  static const _keyOtpExpiry = 'servizipro_otp_expiry';
  static const _keyIsRegistered = 'servizipro_is_registered';
  static const _keyAuthToken = 'servizipro_auth_token';

  Future<void> saveOtpSession({
    required String phone,
     String otp = '',
    String? requestId,
    DateTime? expiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyOtp, otp);
    if (requestId != null) {
      await prefs.setString(_keyRequestId, requestId);
    }
    if (expiresAt != null) {
      await prefs.setString(_keyOtpExpiry, expiresAt.toIso8601String());
    }
  }

  Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhone);
  }

  Future<String?> getStoredOtp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOtp);
  }

  Future<String?> getRequestId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRequestId);
  }

  Future<DateTime?> getOtpExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyOtpExpiry);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> clearOtpSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOtp);
    await prefs.remove(_keyRequestId);
    await prefs.remove(_keyOtpExpiry);
  }

  Future<void> markRegistered({required String authToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsRegistered, true);
    await prefs.setString(_keyAuthToken, authToken);
  }

  Future<bool> isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsRegistered) ?? false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
