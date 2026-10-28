import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';

/// Popup shown after Signup to collect and verify the OTP.
///
/// Pops with `true` when verification succeeds, or `false`/`null` when the
/// user taps "Edit" (they want to change the phone number and go back to
/// the Registration screen).
class OtpDialog extends StatefulWidget {
  final String phoneNumber;
  final String? initialRequestId;
  final int initialExpiresInSeconds;

  const OtpDialog({
    super.key,
    required this.phoneNumber,
    this.initialRequestId,
    this.initialExpiresInSeconds = 120,
  });

  @override
  State<OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<OtpDialog> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _storageService = StorageService();

  String? _requestId;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorText;

  Timer? _resendTimer;
  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    _requestId = widget.initialRequestId;
    _startResendCooldown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _secondsRemaining = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining -= 1);
      }
    });
  }

  Future<void> _onResend() async {
    setState(() {
      _isResending = true;
      _errorText = null;
    });
    try {
       _apiService.resendOtp(widget.phoneNumber, requestId: _requestId);

      await _storageService.saveOtpSession(
        phone: widget.phoneNumber,
        expiresAt: DateTime.now().add(Duration(seconds: 20)),
      );

      _otpController.clear();
      _startResendCooldown();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A new OTP has been sent')));
      }
    } on ApiException catch (e) {
      setState(() => _errorText = e.message);
    } catch (_) {
      setState(() => _errorText = 'Could not resend OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _onEdit() {
    Navigator.of(context).pop(false);
  }

  Future<void> _onVerify() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    final enteredOtp = _otpController.text.trim();

    try {
      // 1) Check against the OTP cached locally after send/resend.
      final expiry = await _storageService.getOtpExpiry();

      if (expiry != null && DateTime.now().isAfter(expiry)) {
        setState(() => _errorText = 'OTP expired. Please resend and try again.');
        return;
      }

     

      // 2) Confirm with the backend so verification is authoritative there.
       _apiService.verifyOtp(
        phoneNumber: widget.phoneNumber,
        otp: enteredOtp,
        requestId: _requestId,
      );

      await _storageService.clearOtpSession();

      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _errorText = e.message);
    } catch (_) {
      setState(() => _errorText = 'Verification failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsRemaining == 0 && !_isResending;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Verify your number', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  TextButton.icon(
                    onPressed: _isVerifying ? null : _onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Enter the 6-digit code sent to +1 ${widget.phoneNumber}', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 20),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(fontSize: 22, letterSpacing: 8),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: '', hintText: '••••••'),
                validator: Validators.validateOtp,
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 4),
                Text(_errorText!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isVerifying ? null : _onVerify,
                child: _isVerifying
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('Verify OTP'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: canResend ? _onResend : null,
                child: Text(canResend ? 'Resend OTP' : 'Resend OTP in $_secondsRemaining s'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
