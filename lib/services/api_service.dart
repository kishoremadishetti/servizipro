import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/environment.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class SendOtpResponse {
  final String otp;
  final String? requestId;
  final int expiresInSeconds;

  SendOtpResponse({
    required this.otp,
    this.requestId,
    this.expiresInSeconds = 120,
  });

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    return SendOtpResponse(
      otp: json['otp'].toString(),
      requestId: json['requestId']?.toString(),
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 120,
    );
  }
}

/// Talks to the Servizipro backend. The base URL is resolved from the
/// active [EnvironmentConfig] (Test / QA / Prod), configured at app start
/// via `flutter run --dart-define=ENV=test|qa|prod`.
class ApiService {
  final http.Client _client;
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  String get _baseUrl => EnvironmentConfig.instance.baseUrl;

  /// Sends the OTP to [phoneNumber] (10-digit, without +1).
  /// Expects the backend to return `{ otp, requestId, expiresInSeconds }`.
  void sendOtp(String phoneNumber) async {
    final uri = Uri.parse('$_baseUrl/api/otp/send');
    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
             body: jsonEncode({
              'phone': '+1$phoneNumber'
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        ApiException('OTP sent successfully', response.statusCode);
      }
      throw ApiException('Unable to send OTP', response.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error while sending OTP: $e');
    }
  }

  /// Requests a fresh OTP for a number that already has an active session.
  void resendOtp(String phoneNumber, {String? requestId}) async {
    final uri = Uri.parse('$_baseUrl/api/otp/send');
    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': '+1$phoneNumber'
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
       ApiException('OTP sent successfully', response.statusCode);
      }
      throw ApiException('Unable to resend OTP', response.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error while resending OTP: $e');
    }
  }

  /// Verifies the OTP server-side and returns an auth token on success.
 void verifyOtp({
    required String phoneNumber,
    required String otp,
    String? requestId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/otp/verify');
    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': '+1$phoneNumber',
              'otp': otp,
              if (requestId != null) 'requestId': requestId,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
         ApiException('OTP verification successful', response.statusCode);
         
        }
        throw ApiException('OTP verification failed');
      }
      throw ApiException('Unable to verify OTP', response.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error while verifying OTP: $e');
    }
  }
}
