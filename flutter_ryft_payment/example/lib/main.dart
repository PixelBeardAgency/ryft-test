import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ryft_payment/flutter_ryft_payment.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ryft Payment Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Ryft Payment Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final RyftPayment _ryftPayment = RyftPayment();
  bool _initialized = false;
  String _resultText = '';

  @override
  void initState() {
    super.initState();
    _initializeRyft();
  }

  Future<void> _initializeRyft() async {
    try {
      await _ryftPayment.initialize(
        publicApiKey: 'your_public_api_key', // Replace with your Ryft public API key
      );
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _resultText = 'Error initializing Ryft: $e';
      });
    }
  }

  Future<void> _showDropIn() async {
    if (!_initialized) {
      setState(() {
        _resultText = 'Ryft not initialized yet';
      });
      return;
    }

    try {
      final config = RyftPaymentConfiguration(
        clientSecret: 'your_client_secret', // Replace with your client secret
        subAccountId: null, // Optional: Replace with your sub account ID if needed
        collectCardholderName: true,
        // Add Apple Pay for iOS
        applePayConfig: Platform.isIOS ? RyftApplePayConfiguration(
          merchantIdentifier: 'merchant.com.yourcompany',
          merchantName: 'Your Company',
          merchantCountryCode: 'US',
        ) : null,
        // Add Google Pay for Android
        googlePayConfig: Platform.isAndroid ? RyftGooglePayConfiguration(
          merchantName: 'Your Company',
          merchantCountryCode: 'US',
        ) : null,
      );

      final result = await _ryftPayment.showDropIn(config: config);

      setState(() {
        _resultText = 'Payment result: ${result.status.name}\n';
        if (result.paymentSession != null) {
          _resultText += 'Session ID: ${result.paymentSession!['id']}\n';
          _resultText += 'Amount: ${result.paymentSession!['amount']}\n';
          _resultText += 'Currency: ${result.paymentSession!['currency']}\n';
        }
        if (result.errorMessage != null) {
          _resultText += 'Error: ${result.errorMessage}\n';
        }
      });
    } catch (e) {
      setState(() {
        _resultText = 'Error showing drop-in: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _initialized ? _showDropIn : null,
              child: const Text('Show Payment Form'),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _resultText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 