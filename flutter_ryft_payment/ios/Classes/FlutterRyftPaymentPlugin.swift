import Flutter
import UIKit
// In a real implementation, uncomment these imports
import RyftCore
import RyftUI

public class FlutterRyftPaymentPlugin: NSObject, FlutterPlugin, RyftDropInPaymentDelegate {
  private var pendingResult: FlutterResult?
  // In a real implementation, this would be RyftDropInPaymentViewController
  private var ryftDropIn: RyftDropInPaymentViewController?
  private var publicApiKey: String?
  private var apiClient: RyftApiClient?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_ryft_payment", binaryMessenger: registrar.messenger())
    let instance = FlutterRyftPaymentPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      if let args = call.arguments as? [String: Any],
         let publicApiKey = args["publicApiKey"] as? String {
        self.publicApiKey = publicApiKey
        
        // Initialize the API client
        let environment = RyftCore.RyftEnvironment.fromPublicKey(publicApiKey)
        self.apiClient = DefaultRyftApiClient(publicApiKey: publicApiKey, environment: environment)
        
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
      }
      
    case "showDropIn":
      guard let args = call.arguments as? [String: Any],
            let clientSecret = args["clientSecret"] as? String,
            let publicApiKey = self.publicApiKey else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments", details: nil))
        return
      }
      
      let subAccountId = args["subAccountId"] as? String
      let collectCardholderName = args["collectCardholderName"] as? Bool ?? false
      
      var applePayConfig: RyftApplePayConfig?
      if let applePayArgs = args["applePayConfig"] as? [String: Any],
         let merchantIdentifier = applePayArgs["merchantIdentifier"] as? String,
         let merchantName = applePayArgs["merchantName"] as? String,
         let merchantCountryCode = applePayArgs["merchantCountryCode"] as? String {
        applePayConfig = RyftApplePayConfig(
          merchantIdentifier: merchantIdentifier,
          merchantCountryCode: merchantCountryCode,
          merchantName: merchantName
        )
      }
      
      let fieldCollection = RyftDropInConfiguration.RyftDropInFieldCollectionConfig(
        nameOnCard: collectCardholderName
      )
      
      let config = RyftDropInConfiguration(
        clientSecret: clientSecret,
        accountId: subAccountId,
        applePay: applePayConfig,
        fieldCollection: fieldCollection
      )
      
      pendingResult = result
      
      if let viewController = UIApplication.shared.keyWindow?.rootViewController {
        ryftDropIn = RyftDropInPaymentViewController(
          config: config,
          publicApiKey: publicApiKey,
          delegate: self
        )
        viewController.present(ryftDropIn!, animated: true, completion: nil)
      } else {
        result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No view controller available", details: nil))
      }
      
    case "processCardPayment":
      guard let args = call.arguments as? [String: Any],
            let clientSecret = args["clientSecret"] as? String,
            let paymentMethodMap = args["paymentMethod"] as? [String: Any],
            let apiClient = self.apiClient else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments", details: nil))
        return
      }
      
      let subAccountId = args["subAccountId"] as? String
      
      // Extract card details
      let cardNumber = paymentMethodMap["cardNumber"] as! String
      let expiryMonth = paymentMethodMap["expiryMonth"] as! String
      let expiryYear = paymentMethodMap["expiryYear"] as! String
      let cvc = paymentMethodMap["cvc"] as! String
      let cardholderName = paymentMethodMap["cardholderName"] as? String
      let storeCard = paymentMethodMap["storeCard"] as? Bool ?? false
      
      // Create card request
      let card = RyftCore.CardRequest(
        number: cardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvc: cvc,
        nameOnCard: cardholderName
      )
      
      pendingResult = result
      
      // Process payment with card
      apiClient.attemptPayment(
        request: AttemptPaymentRequest.fromCard(
          clientSecret: clientSecret,
          card: card,
          storeCard: storeCard
        ),
        accountId: subAccountId,
        completion: { [weak self] paymentResult in
          self?.handleApiPaymentResult(paymentResult, result: result)
        }
      )
      
    case "processSavedPaymentMethod":
      guard let args = call.arguments as? [String: Any],
            let clientSecret = args["clientSecret"] as? String,
            let paymentMethodMap = args["paymentMethod"] as? [String: Any],
            let apiClient = self.apiClient else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments", details: nil))
        return
      }
      
      let subAccountId = args["subAccountId"] as? String
      let paymentMethodId = paymentMethodMap["id"] as! String
      
      pendingResult = result
      
      // Process payment with saved payment method
      apiClient.attemptPayment(
        request: AttemptPaymentRequest.fromPaymentMethod(
          clientSecret: clientSecret,
          paymentMethodId: paymentMethodId
        ),
        accountId: subAccountId,
        completion: { [weak self] paymentResult in
          self?.handleApiPaymentResult(paymentResult, result: result)
        }
      )
      
    case "processApplePayPayment":
      guard let args = call.arguments as? [String: Any],
            let clientSecret = args["clientSecret"] as? String,
            let publicApiKey = self.publicApiKey else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments", details: nil))
        return
      }
      
      let subAccountId = args["subAccountId"] as? String
      
      // For Apple Pay, we'd usually create a RyftApplePayComponent and handle the payment
      // Here we'll use a simplified approach that directly calls the API
      
      // Note: In a real implementation, this would be more complex and involve
      // presenting the Apple Pay sheet to the user
      
      pendingResult = result
      
      // For now, just notify that Apple Pay requires interactive handling
      result([
        "status": "failed",
        "errorMessage": "Apple Pay requires user interaction. Please use showDropIn instead."
      ])
      
    case "checkPaymentStatus":
      guard let args = call.arguments as? [String: Any],
            let paymentSessionId = args["paymentSessionId"] as? String,
            let clientSecret = args["clientSecret"] as? String,
            let apiClient = self.apiClient else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments", details: nil))
        return
      }
      
      let subAccountId = args["subAccountId"] as? String
      
      pendingResult = result
      
      // Get the latest payment session
      apiClient.getPaymentSession(
        id: paymentSessionId,
        clientSecret: clientSecret,
        accountId: subAccountId,
        completion: { [weak self] paymentResult in
          self?.handleApiPaymentResult(paymentResult, result: result)
        }
      )
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func handleApiPaymentResult(_ paymentResult: Result<PaymentSession, HttpError>, result: FlutterResult) {
    switch paymentResult {
    case .success(let paymentSession):
      if let requiredAction = paymentSession.requiredAction {
        // Payment requires additional action
        result([
          "status": "requiresAction",
          "actionType": requiredAction.type.rawValue,
          "paymentSession": [
            "id": paymentSession.id,
            "amount": paymentSession.amount,
            "currency": paymentSession.currency,
            "status": paymentSession.status.rawValue
          ]
        ])
      } else {
        // Payment successful
        result([
          "status": "approved",
          "paymentSession": [
            "id": paymentSession.id,
            "amount": paymentSession.amount,
            "currency": paymentSession.currency,
            "status": paymentSession.status.rawValue
          ]
        ])
      }
      
    case .failure(let error):
      // Payment failed
      result([
        "status": "failed",
        "errorMessage": error.localizedDescription
      ])
    }
  }
  
  // MARK: - RyftDropInPaymentDelegate
  public func onPaymentResult(result: RyftPaymentResult) {
    guard let pendingResult = pendingResult else { return }
    self.pendingResult = nil
    
    switch result {
    case .success(let paymentSession):
      let sessionMap: [String: Any] = [
        "id": paymentSession.id,
        "amount": paymentSession.amount,
        "currency": paymentSession.currency,
        "status": paymentSession.status.rawValue
      ]
      
      pendingResult([
        "status": "approved",
        "paymentSession": sessionMap
      ])
      
    case .failed(let error):
      pendingResult([
        "status": "failed",
        "errorMessage": error.displayError
      ])
      
    case .cancelled:
      pendingResult([
        "status": "cancelled"
      ])
      
    case .pendingAction(let paymentSession, let requiredAction):
      // Handle 3DS actions
      ryftDropIn?.handleRequiredAction(
        returnUrl: URL(string: paymentSession.returnUrl),
        requiredAction
      )
    }
  }
} 