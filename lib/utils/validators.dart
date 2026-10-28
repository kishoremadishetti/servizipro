class Validators {
  /// Indian mobile numbers: exactly 10 digits, starting with 6, 7, 8, or 9.
  static final RegExp _indianMobileRegex = RegExp(r'^[6-9]\d{9}$');

  /// Strips a leading country code / trunk prefix so the value can be
  /// checked against the 10-digit Indian mobile format.
  static String normalizeIndianPhone(String value) {
    var v = value.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (v.startsWith('+1')) {
      v = v.substring(3);
    } else if (v.startsWith('1') && v.length == 12) {
      v = v.substring(2);
    } else if (v.startsWith('0') && v.length == 11) {
      v = v.substring(1);
    }
    return v;
  }

  static String? validateIndianPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = normalizeIndianPhone(value);
    if (!_indianMobileRegex.hasMatch(cleaned)) {
      return 'Enter a valid 10-digit Indian mobile number';
    }
    return null;
  }

  static String? validateOtp(String? value, {int length = 6}) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    final trimmed = value.trim();
    if (trimmed.length != length) {
      return 'Enter the $length-digit OTP';
    }
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'OTP must contain digits only';
    }
    return null;
  }
}
