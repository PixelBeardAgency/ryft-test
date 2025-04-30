package com.ryft.flutter_ryft_payment

import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull
import com.ryftpay.android.core.model.api.RyftPublicApiKey
import com.ryftpay.android.core.model.payment.*
import com.ryftpay.android.core.service.DefaultRyftPaymentService
import com.ryftpay.android.core.service.RyftPaymentService
import com.ryftpay.android.core.service.listener.RyftPaymentResultListener
import com.ryftpay.android.ui.dropin.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.ryftpay.android.core.client.RyftApiClient
import com.ryftpay.android.core.client.DefaultRyftApiClientFactory
import com.ryftpay.android.core.model.error.RyftError
import com.ryftpay.android.core.service.listener.RyftLoadPaymentListener

class FlutterRyftPaymentPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, RyftDropInResultListener {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private var activity: Activity? = null
  private var ryftDropIn: RyftDropIn? = null
  private var pendingResult: Result? = null
  private var ryftPublicApiKey: RyftPublicApiKey? = null
  private lateinit var ryftPaymentService: RyftPaymentService
  private var ryftApiClient: RyftApiClient? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_ryft_payment")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "initialize" -> {
        val publicApiKey = call.argument<String>("publicApiKey")
        if (publicApiKey == null) {
          result.error("MISSING_ARG", "Public API key is required", null)
          return
        }
        ryftPublicApiKey = RyftPublicApiKey(publicApiKey)
        
        // Initialize the API client and payment service
        ryftApiClient = DefaultRyftApiClientFactory(ryftPublicApiKey!!).createApiClient()
        ryftPaymentService = DefaultRyftPaymentService(ryftApiClient!!)
        
        result.success(null)
      }
      "showDropIn" -> {
        val clientSecret = call.argument<String>("clientSecret")
        val subAccountId = call.argument<String>("subAccountId")
        val collectCardholderName = call.argument<Boolean>("collectCardholderName") ?: false
        val googlePayConfig = call.argument<Map<String, Any>>("googlePayConfig")

        if (clientSecret == null) {
          result.error("MISSING_ARG", "Client secret is required", null)
          return
        }

        val fieldCollection = RyftDropInFieldCollectionConfiguration(
          nameOnCard = collectCardholderName
        )

        var googlePayConfiguration: RyftDropInGooglePayConfiguration? = null
        if (googlePayConfig != null) {
          googlePayConfiguration = RyftDropInGooglePayConfiguration(
            merchantName = googlePayConfig["merchantName"] as String,
            merchantCountryCode = googlePayConfig["merchantCountryCode"] as String
          )
        }

        val configuration = if (subAccountId != null) {
          RyftDropInConfiguration.subAccountPayment(
            clientSecret = clientSecret,
            subAccountId = subAccountId,
            fieldCollection = fieldCollection,
            googlePayConfiguration = googlePayConfiguration,
            publicApiKey = ryftPublicApiKey
          )
        } else {
          RyftDropInConfiguration.standardAccountPayment(
            clientSecret = clientSecret,
            fieldCollection = fieldCollection,
            googlePayConfiguration = googlePayConfiguration,
            publicApiKey = ryftPublicApiKey
          )
        }

        pendingResult = result

        activity?.let {
          ryftDropIn = DefaultRyftDropIn(
            activity = it,
            listener = this
          )
          ryftDropIn?.show(configuration)
        } ?: run {
          result.error("NO_ACTIVITY", "Activity is not available", null)
        }
      }
      "processCardPayment" -> {
        val clientSecret = call.argument<String>("clientSecret")
        val paymentMethodMap = call.argument<Map<String, Any>>("paymentMethod")
        val subAccountId = call.argument<String>("subAccountId")

        if (clientSecret == null || paymentMethodMap == null) {
          result.error("MISSING_ARG", "Client secret and payment method are required", null)
          return
        }

        val cardNumber = paymentMethodMap["cardNumber"] as String
        val expiryMonth = paymentMethodMap["expiryMonth"] as String
        val expiryYear = paymentMethodMap["expiryYear"] as String
        val cvc = paymentMethodMap["cvc"] as String
        val cardholderName = paymentMethodMap["cardholderName"] as? String
        val storeCard = paymentMethodMap["storeCard"] as? Boolean ?: false

        val cardDetails = CardDetails(
          number = cardNumber,
          expiryMonth = expiryMonth,
          expiryYear = expiryYear,
          cvc = cvc,
          nameOnCard = cardholderName
        )

        val options = PaymentMethodOptions.card(store = storeCard)
        val paymentMethod = PaymentMethod.card(cardDetails, options)

        pendingResult = result
        
        // Real implementation using the Ryft SDK
        ryftPaymentService.attemptPayment(
          clientSecret = clientSecret,
          paymentMethod = paymentMethod,
          customerDetails = null,
          subAccountId = subAccountId,
          listener = createPaymentResultListener()
        )
      }
      "processSavedPaymentMethod" -> {
        val clientSecret = call.argument<String>("clientSecret")
        val paymentMethodMap = call.argument<Map<String, Any>>("paymentMethod")
        val subAccountId = call.argument<String>("subAccountId")

        if (clientSecret == null || paymentMethodMap == null) {
          result.error("MISSING_ARG", "Client secret and payment method are required", null)
          return
        }

        val paymentMethodId = paymentMethodMap["id"] as String
        val paymentMethod = PaymentMethod.id(paymentMethodId)

        pendingResult = result
        
        // Real implementation using the Ryft SDK
        ryftPaymentService.attemptPayment(
          clientSecret = clientSecret,
          paymentMethod = paymentMethod,
          customerDetails = null,
          subAccountId = subAccountId,
          listener = createPaymentResultListener()
        )
      }
      "processGooglePayPayment" -> {
        val clientSecret = call.argument<String>("clientSecret")
        val paymentMethodMap = call.argument<Map<String, Any>>("paymentMethod")
        val subAccountId = call.argument<String>("subAccountId")

        if (clientSecret == null || paymentMethodMap == null) {
          result.error("MISSING_ARG", "Client secret and payment method are required", null)
          return
        }

        val token = paymentMethodMap["token"] as String
        val paymentMethod = PaymentMethod.googlePay(token, billingAddress = null)

        pendingResult = result
        
        // Real implementation using the Ryft SDK
        ryftPaymentService.attemptPayment(
          clientSecret = clientSecret,
          paymentMethod = paymentMethod,
          customerDetails = null,
          subAccountId = subAccountId,
          listener = createPaymentResultListener()
        )
      }
      "checkPaymentStatus" -> {
        val paymentSessionId = call.argument<String>("paymentSessionId")
        val clientSecret = call.argument<String>("clientSecret")
        val subAccountId = call.argument<String>("subAccountId")

        if (paymentSessionId == null || clientSecret == null) {
          result.error("MISSING_ARG", "Payment session ID and client secret are required", null)
          return
        }

        pendingResult = result
        
        // Check the payment status
        ryftPaymentService.getLatestPaymentResult(
          paymentSessionId = paymentSessionId,
          clientSecret = clientSecret,
          subAccountId = subAccountId,
          listener = createPaymentResultListener()
        )
      }
      else -> result.notImplemented()
    }
  }
  
  private fun createPaymentResultListener(): RyftPaymentResultListener {
    return object : RyftPaymentResultListener {
      override fun onAttemptingPayment() {
        // Payment is being attempted
      }
      
      override fun onLoadingPaymentResult() {
        // Payment result is being loaded
      }
      
      override fun onPaymentApproved(response: PaymentSession) {
        val result = pendingResult ?: return
        pendingResult = null
        
        val sessionMap = mapOf(
          "id" to response.id,
          "amount" to response.amount,
          "currency" to response.currency.currencyCode,
          "status" to response.status.name
        )
        
        result.success(mapOf(
          "status" to "approved",
          "paymentSession" to sessionMap
        ))
      }
      
      override fun onPaymentRequiresRedirect(returnUrl: String, redirectUrl: String) {
        val result = pendingResult ?: return
        pendingResult = null
        
        result.success(mapOf(
          "status" to "requiresAction",
          "actionType" to "redirect",
          "returnUrl" to returnUrl,
          "redirectUrl" to redirectUrl
        ))
      }
      
      override fun onPaymentRequiresIdentification(returnUrl: String, identifyAction: IdentifyAction) {
        val result = pendingResult ?: return
        pendingResult = null
        
        // In a complete implementation, we'd handle 3DS here
        // For now, we'll return a result indicating that 3DS is required
        result.success(mapOf(
          "status" to "requiresAction",
          "actionType" to "identify",
          "returnUrl" to returnUrl
        ))
      }
      
      override fun onPaymentHasError(lastError: PaymentSessionError) {
        val result = pendingResult ?: return
        pendingResult = null
        
        result.success(mapOf(
          "status" to "failed",
          "errorMessage" to lastError.displayError
        ))
      }
      
      override fun onErrorObtainingPaymentResult(error: RyftError?, throwable: Throwable?) {
        val result = pendingResult ?: return
        pendingResult = null
        
        result.success(mapOf(
          "status" to "failed",
          "errorMessage" to (error?.displayError ?: throwable?.message ?: "Unknown error")
        ))
      }
    }
  }

  override fun onPaymentResult(paymentResult: com.ryftpay.android.ui.model.RyftPaymentResult) {
    val result = pendingResult ?: return
    pendingResult = null

    when (paymentResult) {
      is com.ryftpay.android.ui.model.RyftPaymentResult.Approved -> {
        val sessionMap = mapOf(
          "id" to paymentResult.paymentSession.id,
          "amount" to paymentResult.paymentSession.amount,
          "currency" to paymentResult.paymentSession.currency.currencyCode,
          "status" to paymentResult.paymentSession.status.name
        )

        result.success(mapOf(
          "status" to "approved",
          "paymentSession" to sessionMap
        ))
      }
      is com.ryftpay.android.ui.model.RyftPaymentResult.Failed -> {
        result.success(mapOf(
          "status" to "failed",
          "errorMessage" to paymentResult.error.displayError
        ))
      }
      is com.ryftpay.android.ui.model.RyftPaymentResult.Cancelled -> {
        result.success(mapOf(
          "status" to "cancelled"
        ))
      }
    }
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
} 