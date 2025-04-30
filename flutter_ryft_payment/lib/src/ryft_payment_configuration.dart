/// Configuration for Apple Pay
class RyftApplePayConfiguration {
  /// The merchant identifier registered with Apple
  final String merchantIdentifier;
  
  /// The merchant name to be displayed on the Apple Pay sheet
  final String merchantName;
  
  /// The merchant's country code (ISO 3166-1 alpha-2 country code)
  final String merchantCountryCode;
  
  /// Creates a new Apple Pay configuration
  RyftApplePayConfiguration({
    required this.merchantIdentifier,
    required this.merchantName,
    required this.merchantCountryCode,
  });
  
  /// Converts this configuration to a map for platform channel communication
  Map<String, dynamic> toMap() {
    return {
      'merchantIdentifier': merchantIdentifier,
      'merchantName': merchantName,
      'merchantCountryCode': merchantCountryCode,
    };
  }
}

/// Configuration for Google Pay
class RyftGooglePayConfiguration {
  /// The merchant name to be displayed on the Google Pay sheet
  final String merchantName;
  
  /// The merchant's country code (ISO 3166-1 alpha-2 country code)
  final String merchantCountryCode;
  
  /// Creates a new Google Pay configuration
  RyftGooglePayConfiguration({
    required this.merchantName,
    required this.merchantCountryCode,
  });
  
  /// Converts this configuration to a map for platform channel communication
  Map<String, dynamic> toMap() {
    return {
      'merchantName': merchantName,
      'merchantCountryCode': merchantCountryCode,
    };
  }
}

/// Configuration for Ryft payments
class RyftPaymentConfiguration {
  /// The client secret of the payment session
  final String clientSecret;
  
  /// The ID of the sub-account you are taking payments for (optional)
  final String? subAccountId;
  
  /// Whether to collect the cardholder name during payment
  final bool collectCardholderName;
  
  /// Configuration for Apple Pay (iOS only)
  final RyftApplePayConfiguration? applePayConfig;
  
  /// Configuration for Google Pay (Android only)
  final RyftGooglePayConfiguration? googlePayConfig;
  
  /// Creates a new payment configuration
  RyftPaymentConfiguration({
    required this.clientSecret,
    this.subAccountId,
    this.collectCardholderName = false,
    this.applePayConfig,
    this.googlePayConfig,
  });
  
  /// Converts this configuration to a map for platform channel communication
  Map<String, dynamic> toMap() {
    return {
      'clientSecret': clientSecret,
      if (subAccountId != null) 'subAccountId': subAccountId,
      'collectCardholderName': collectCardholderName,
      if (applePayConfig != null) 'applePayConfig': applePayConfig!.toMap(),
      if (googlePayConfig != null) 'googlePayConfig': googlePayConfig!.toMap(),
    };
  }
} 