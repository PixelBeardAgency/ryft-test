/// Base class for payment methods
abstract class RyftPaymentMethod {
  /// Converts this payment method to a map for platform channel communication
  Map<String, dynamic> toMap();
}

/// Payment method for card payments
class RyftCardPaymentMethod extends RyftPaymentMethod {
  /// The card number
  final String cardNumber;
  
  /// The expiry month (1-12)
  final String expiryMonth;
  
  /// The expiry year (4 digits)
  final String expiryYear;
  
  /// The card verification code (CVC/CVV)
  final String cvc;
  
  /// The cardholder name (optional)
  final String? cardholderName;
  
  /// Whether to store the card for future payments
  final bool storeCard;
  
  /// Creates a new card payment method
  RyftCardPaymentMethod({
    required this.cardNumber,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvc,
    this.cardholderName,
    this.storeCard = false,
  });
  
  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'card',
      'cardNumber': cardNumber,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cvc': cvc,
      if (cardholderName != null) 'cardholderName': cardholderName,
      'storeCard': storeCard,
    };
  }
}

/// Payment method for saved payment methods
class RyftSavedPaymentMethod extends RyftPaymentMethod {
  /// The ID of the saved payment method
  final String id;
  
  /// Creates a new saved payment method
  RyftSavedPaymentMethod({
    required this.id,
  });
  
  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'id',
      'id': id,
    };
  }
}

/// Payment method for Google Pay
class RyftGooglePayPaymentMethod extends RyftPaymentMethod {
  /// The Google Pay token
  final String token;
  
  /// Creates a new Google Pay payment method
  RyftGooglePayPaymentMethod({
    required this.token,
  });
  
  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'googlePay',
      'token': token,
    };
  }
}

/// Payment method for Apple Pay
class RyftApplePayPaymentMethod extends RyftPaymentMethod {
  /// Creates a new Apple Pay payment method
  RyftApplePayPaymentMethod();
  
  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'applePay',
    };
  }
} 