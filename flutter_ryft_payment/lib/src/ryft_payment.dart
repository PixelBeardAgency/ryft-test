import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ryft_payment_configuration.dart';
import 'ryft_payment_method.dart';
import 'ryft_payment_result.dart';

/// The main class for interacting with the Ryft payment SDKs
class RyftPayment {
  static final RyftPayment _instance = RyftPayment._internal();
  
  /// Returns the singleton instance of [RyftPayment]
  factory RyftPayment() => _instance;
  
  RyftPayment._internal();
  
  /// The method channel used to communicate with the native code
  final MethodChannel _channel = const MethodChannel('flutter_ryft_payment');
  
  /// Initializes the Ryft payment SDK with your public API key
  /// 
  /// This must be called before any other methods
  Future<void> initialize({
    required String publicApiKey,
  }) async {
    await _channel.invokeMethod<void>('initialize', {
      'publicApiKey': publicApiKey,
    });
  }
  
  /// Shows the Ryft drop-in payment UI
  /// 
  /// Returns a [RyftPaymentResult] when the payment is complete
  Future<RyftPaymentResult> showDropIn({
    required RyftPaymentConfiguration config,
  }) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'showDropIn', 
      config.toMap(),
    );
    
    final paymentResult = RyftPaymentResult.fromMap(
      Map<String, dynamic>.from(result!),
    );
    
    // If the payment requires action, handle it
    if (paymentResult.status == RyftPaymentResultStatus.requiresAction) {
      return await _handleRequiredAction(paymentResult);
    }
    
    return paymentResult;
  }
  
  /// Processes a payment with a card
  /// 
  /// Returns a [RyftPaymentResult] when the payment is complete
  Future<RyftPaymentResult> processCardPayment({
    required String clientSecret,
    required RyftCardPaymentMethod paymentMethod,
    String? subAccountId,
  }) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'processCardPayment', 
      {
        'clientSecret': clientSecret,
        'paymentMethod': paymentMethod.toMap(),
        if (subAccountId != null) 'subAccountId': subAccountId,
      },
    );
    
    final paymentResult = RyftPaymentResult.fromMap(
      Map<String, dynamic>.from(result!),
    );
    
    // If the payment requires action, handle it
    if (paymentResult.status == RyftPaymentResultStatus.requiresAction) {
      return await _handleRequiredAction(paymentResult);
    }
    
    return paymentResult;
  }
  
  /// Processes a payment with a saved payment method
  /// 
  /// Returns a [RyftPaymentResult] when the payment is complete
  Future<RyftPaymentResult> processSavedPaymentMethod({
    required String clientSecret,
    required RyftSavedPaymentMethod paymentMethod,
    String? subAccountId,
  }) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'processSavedPaymentMethod', 
      {
        'clientSecret': clientSecret,
        'paymentMethod': paymentMethod.toMap(),
        if (subAccountId != null) 'subAccountId': subAccountId,
      },
    );
    
    final paymentResult = RyftPaymentResult.fromMap(
      Map<String, dynamic>.from(result!),
    );
    
    // If the payment requires action, handle it
    if (paymentResult.status == RyftPaymentResultStatus.requiresAction) {
      return await _handleRequiredAction(paymentResult);
    }
    
    return paymentResult;
  }
  
  /// Processes a payment with Google Pay (Android only)
  /// 
  /// Returns a [RyftPaymentResult] when the payment is complete
  Future<RyftPaymentResult> processGooglePayPayment({
    required String clientSecret,
    required RyftGooglePayPaymentMethod paymentMethod,
    String? subAccountId,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Google Pay is only supported on Android');
    }
    
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'processGooglePayPayment', 
      {
        'clientSecret': clientSecret,
        'paymentMethod': paymentMethod.toMap(),
        if (subAccountId != null) 'subAccountId': subAccountId,
      },
    );
    
    final paymentResult = RyftPaymentResult.fromMap(
      Map<String, dynamic>.from(result!),
    );
    
    // If the payment requires action, handle it
    if (paymentResult.status == RyftPaymentResultStatus.requiresAction) {
      return await _handleRequiredAction(paymentResult);
    }
    
    return paymentResult;
  }
  
  /// Processes a payment with Apple Pay (iOS only)
  /// 
  /// Returns a [RyftPaymentResult] when the payment is complete
  Future<RyftPaymentResult> processApplePayPayment({
    required String clientSecret,
    String? subAccountId,
  }) async {
    if (!Platform.isIOS) {
      throw UnsupportedError('Apple Pay is only supported on iOS');
    }
    
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'processApplePayPayment', 
      {
        'clientSecret': clientSecret,
        if (subAccountId != null) 'subAccountId': subAccountId,
      },
    );
    
    final paymentResult = RyftPaymentResult.fromMap(
      Map<String, dynamic>.from(result!),
    );
    
    // If the payment requires action, handle it
    if (paymentResult.status == RyftPaymentResultStatus.requiresAction) {
      return await _handleRequiredAction(paymentResult);
    }
    
    return paymentResult;
  }
  
  /// Handles a required action for a payment
  /// 
  /// This is used internally by the other methods
  Future<RyftPaymentResult> _handleRequiredAction(RyftPaymentResult result) async {
    // Check if we have an action type
    if (result.actionType == null) {
      throw StateError('Payment requires action but no action type was provided');
    }
    
    switch (result.actionType!) {
      case RyftRequiredActionType.redirect:
        // Handle redirect action
        if (result.redirectUrl == null || result.returnUrl == null) {
          throw StateError('Redirect action is missing URLs');
        }
        
        // Launch the redirect URL and wait for the user to complete the action
        await _launchUrl(Uri.parse(result.redirectUrl!));
        
        // The user will be redirected to the return URL after completing the action
        // In a real app, you'd need to handle the redirect back to your app
        
        // For now, we'll just check the payment status after a delay
        await Future.delayed(const Duration(seconds: 5));
        
        return await _checkPaymentStatus(result.paymentSession!['id'] as String, result.returnUrl!);
        
      case RyftRequiredActionType.identify:
        // Handle identify action (3DS app-to-app)
        // This requires native implementation via the drop-in
        throw UnsupportedError('Identify action currently requires using the drop-in UI');
        
      case RyftRequiredActionType.unknown:
      default:
        throw UnsupportedError('Unknown action type: ${result.actionType}');
    }
  }
  
  /// Launches a URL
  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
  
  /// Checks the status of a payment
  Future<RyftPaymentResult> _checkPaymentStatus(String paymentSessionId, String returnUrl) async {
    // Extract client secret from the return URL
    final uri = Uri.parse(returnUrl);
    final clientSecret = uri.queryParameters['client_secret'];
    
    if (clientSecret == null) {
      throw StateError('Return URL is missing client_secret parameter');
    }
    
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'checkPaymentStatus', 
      {
        'paymentSessionId': paymentSessionId,
        'clientSecret': clientSecret,
      },
    );
    
    return RyftPaymentResult.fromMap(
      Map<String, dynamic>.from(result!),
    );
  }
} 