/// Represents the status of a payment operation
enum RyftPaymentResultStatus {
  /// Payment was approved
  approved,
  
  /// Payment failed
  failed,
  
  /// Payment was cancelled by the user
  cancelled,
  
  /// Payment requires additional action (like 3DS)
  requiresAction,
}

/// The type of action required for a payment
enum RyftRequiredActionType {
  /// Redirect to a URL for 3DS verification
  redirect,
  
  /// App-to-app 3DS verification
  identify,
  
  /// Unknown action type
  unknown
}

/// Represents the result of a payment operation
class RyftPaymentResult {
  /// The status of the payment
  final RyftPaymentResultStatus status;
  
  /// Payment session data if available
  final Map<String, dynamic>? paymentSession;
  
  /// Error message if the payment failed
  final String? errorMessage;
  
  /// The type of required action if the status is requiresAction
  final RyftRequiredActionType? actionType;
  
  /// The return URL for redirect actions
  final String? returnUrl;
  
  /// The redirect URL for redirect actions
  final String? redirectUrl;
  
  /// Constructs a new payment result
  RyftPaymentResult({
    required this.status,
    this.paymentSession,
    this.errorMessage,
    this.actionType,
    this.returnUrl,
    this.redirectUrl,
  });
  
  /// Creates a payment result from a map received from the platform channel
  factory RyftPaymentResult.fromMap(Map<String, dynamic> map) {
    final status = RyftPaymentResultStatus.values.byName(map['status'] as String);
    
    RyftRequiredActionType? actionType;
    if (status == RyftPaymentResultStatus.requiresAction && map['actionType'] != null) {
      switch (map['actionType']) {
        case 'redirect':
          actionType = RyftRequiredActionType.redirect;
          break;
        case 'identify':
          actionType = RyftRequiredActionType.identify;
          break;
        default:
          actionType = RyftRequiredActionType.unknown;
      }
    }
    
    return RyftPaymentResult(
      status: status,
      paymentSession: map['paymentSession'] as Map<String, dynamic>?,
      errorMessage: map['errorMessage'] as String?,
      actionType: actionType,
      returnUrl: map['returnUrl'] as String?,
      redirectUrl: map['redirectUrl'] as String?,
    );
  }
  
  /// Converts this result to a map for platform channel communication
  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      if (paymentSession != null) 'paymentSession': paymentSession,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (actionType != null) 'actionType': actionType?.name,
      if (returnUrl != null) 'returnUrl': returnUrl,
      if (redirectUrl != null) 'redirectUrl': redirectUrl,
    };
  }
} 