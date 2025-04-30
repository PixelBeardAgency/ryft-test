# Flutter Ryft Payment

[![pub package](https://img.shields.io/pub/v/flutter_ryft_payment.svg)](https://pub.dev/packages/flutter_ryft_payment)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A Flutter plugin implementing Ryft payment SDKs for both Android and iOS platforms.

## Features

- Process payments with credit/debit cards
- Support for Google Pay (Android) and Apple Pay (iOS)
- Drop-in UI for payment processing
- 3D Secure authentication support
- Support for saved payment methods

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_ryft_payment: ^0.1.0
```

Then run:

```
flutter pub get
```

### Android Setup

Ensure your minimum SDK version is set to 21 or higher in your `android/app/build.gradle` file:

```gradle
defaultConfig {
    minSdkVersion 21
    // ...
}
```

### iOS Setup

Ensure your minimum deployment target is set to iOS 12.0 or higher in your `ios/Podfile`:

```ruby
platform :ios, '12.0'
```

If you want to use Apple Pay, you'll need to add the necessary entitlements to your iOS app.

## Usage

### Initializing the SDK

Initialize the SDK as early as possible in your app, typically in the `main.dart` file:

```dart
import 'package:flutter_ryft_payment/flutter_ryft_payment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await RyftPayment().initialize(
    publicApiKey: 'your_ryft_public_api_key',
  );
  
  runApp(MyApp());
}
```

### Showing the Drop-in Payment UI

To show the drop-in payment UI:

```dart
import 'dart:io';
import 'package:flutter_ryft_payment/flutter_ryft_payment.dart';

Future<void> showPaymentForm() async {
  try {
    final config = RyftPaymentConfiguration(
      clientSecret: 'your_client_secret', // Get this from your backend
      subAccountId: 'optional_sub_account_id', // Optional
      collectCardholderName: true, // Whether to collect cardholder name
      // Configure Apple Pay for iOS
      applePayConfig: Platform.isIOS ? RyftApplePayConfiguration(
        merchantIdentifier: 'merchant.com.yourcompany',
        merchantName: 'Your Company',
        merchantCountryCode: 'US',
      ) : null,
      // Configure Google Pay for Android
      googlePayConfig: Platform.isAndroid ? RyftGooglePayConfiguration(
        merchantName: 'Your Company',
        merchantCountryCode: 'US',
      ) : null,
    );

    final result = await RyftPayment().showDropIn(config: config);
    
    // Handle the result
    switch (result.status) {
      case RyftPaymentResultStatus.approved:
        print('Payment approved: ${result.paymentSession}');
        break;
      case RyftPaymentResultStatus.failed:
        print('Payment failed: ${result.errorMessage}');
        break;
      case RyftPaymentResultStatus.cancelled:
        print('Payment cancelled');
        break;
      case RyftPaymentResultStatus.requiresAction:
        print('Payment requires additional action');
        break;
    }
  } catch (e) {
    print('Error showing payment form: $e');
  }
}
```

### Processing a Payment with a Card

To process a payment with a card:

```dart
Future<void> processCardPayment() async {
  try {
    final paymentMethod = RyftCardPaymentMethod(
      cardNumber: '4242424242424242',
      expiryMonth: '12',
      expiryYear: '2025',
      cvc: '123',
      cardholderName: 'John Doe', // Optional
      storeCard: false, // Whether to store the card for future payments
    );
    
    final result = await RyftPayment().processCardPayment(
      clientSecret: 'your_client_secret',
      paymentMethod: paymentMethod,
      subAccountId: 'optional_sub_account_id', // Optional
    );
    
    // Handle the result
    // ...
  } catch (e) {
    print('Error processing card payment: $e');
  }
}
```

### Processing a Payment with a Saved Payment Method

To process a payment with a saved payment method:

```dart
Future<void> processSavedPaymentMethod() async {
  try {
    final paymentMethod = RyftSavedPaymentMethod(
      id: 'saved_payment_method_id',
    );
    
    final result = await RyftPayment().processSavedPaymentMethod(
      clientSecret: 'your_client_secret',
      paymentMethod: paymentMethod,
      subAccountId: 'optional_sub_account_id', // Optional
    );
    
    // Handle the result
    // ...
  } catch (e) {
    print('Error processing saved payment method: $e');
  }
}
```

### Processing a Payment with Google Pay (Android only)

To process a payment with Google Pay:

```dart
Future<void> processGooglePayPayment() async {
  try {
    final paymentMethod = RyftGooglePayPaymentMethod(
      token: 'google_pay_token', // Get this from the Google Pay SDK
    );
    
    final result = await RyftPayment().processGooglePayPayment(
      clientSecret: 'your_client_secret',
      paymentMethod: paymentMethod,
      subAccountId: 'optional_sub_account_id', // Optional
    );
    
    // Handle the result
    // ...
  } catch (e) {
    print('Error processing Google Pay payment: $e');
  }
}
```

### Processing a Payment with Apple Pay (iOS only)

To process a payment with Apple Pay:

```dart
Future<void> processApplePayPayment() async {
  try {
    final result = await RyftPayment().processApplePayPayment(
      clientSecret: 'your_client_secret',
      subAccountId: 'optional_sub_account_id', // Optional
    );
    
    // Handle the result
    // ...
  } catch (e) {
    print('Error processing Apple Pay payment: $e');
  }
}
```

## Example

See the [example](example) directory for a complete sample app.

## Contributing

Contributions are welcome! If you find a bug or want a feature, please open an issue.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 