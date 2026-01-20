import 'package:flutter/services.dart';

class ValidationUtils {
  // Email Validation Regex
  static final RegExp _emailRegex = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  // CNIC Validation Regex (12345-1234567-1)
  static final RegExp _cnicRegex = RegExp(
    r'^\d{5}-\d{7}-\d{1}$',
  );

  /// Checks if the email is valid
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    return _emailRegex.hasMatch(email.trim());
  }

  /// Checks if the CNIC is valid (Format: 12345-1234567-1)
  static bool isValidCNIC(String cnic) {
    if (cnic.isEmpty) return false;
    return _cnicRegex.hasMatch(cnic.trim());
  }
}

/// Custom formatter for CNIC (12345-1234567-1)
class CNICFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If text is being deleted, don't auto-format to avoid fighting the user
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    // Only allow digits
    String cleaned = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Limit to 13 digits (which results in 15 characters total with dashes)
    if (cleaned.length > 13) {
      cleaned = cleaned.substring(0, 13);
    }
    
    String formatted = '';
    for (int i = 0; i < cleaned.length; i++) {
      formatted += cleaned[i];
      if ((i == 4 || i == 11) && i != cleaned.length - 1) {
        formatted += '-';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
