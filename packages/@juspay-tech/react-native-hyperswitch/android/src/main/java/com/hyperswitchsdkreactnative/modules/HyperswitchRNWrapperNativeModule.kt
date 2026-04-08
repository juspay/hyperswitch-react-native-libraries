package com.hyperswitchsdkreactnative.modules

import android.util.Log
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.facebook.react.uimanager.IllegalViewOperationException
import com.facebook.react.uimanager.UIManagerModule
import com.hyperswitchsdkreactnative.NativeHyperswitchSdkReactNativeSpec
import com.hyperswitchsdkreactnative.headless.HeadlessFlowController
import com.hyperswitchsdkreactnative.headless.PMError
import com.hyperswitchsdkreactnative.headless.PaymentMethodType
import com.hyperswitchsdkreactnative.headless.HeadlessPaymentResult
import com.hyperswitchsdkreactnative.headless.PaymentSessionHandler
import com.hyperswitchsdkreactnative.provider.HyperProvider
import com.hyperswitchsdkreactnative.views.PaymentWidgetView
import org.json.JSONObject


class HyperswitchRNWrapperNativeModule(reactContext: ReactApplicationContext) :
  NativeHyperswitchSdkReactNativeSpec(reactContext) {

  private var hyperProvider: HyperProvider? = null

  init {
    currentInstance = this
    hostReactContext = reactContext
  }

  override fun getName(): String {
    return NAME
  }

  override fun initialise(
    publishableKey: String,
    customBackendUrl: String?,
    customLogUrl: String?,
    customParams: ReadableMap?,
    promise: Promise?
  ) {
    try {
      currentActivity?.let { activity ->
        hyperProvider = HyperProvider(activity)
        hyperProvider!!.initialise(publishableKey, customBackendUrl, customLogUrl, customParams)
        promise?.resolve(null)
      } ?: run {
        promise?.reject("INITIALIZATION_ERROR", "Current activity is null")
      }
    } catch (e: Exception) {
      promise?.reject("INITIALIZATION_ERROR", "Failed to initialize Hyperswitch SDK: ${e.message}")
    }
  }

  override fun initPaymentSession(sdkAuthorization: String?, promise: Promise?) {
    try {
      hyperProvider?.let { provider ->
        // Clean up stale state from any previous payment session.
        HeadlessFlowController.reset()
        paymentSessionHandler = null

        sdkAuthorization?.let {
          provider.initPaymentSession(sdkAuthorization = sdkAuthorization)
        }
        promise?.resolve(null)
      } ?: run {
        promise?.reject("INIT_ERROR", "HyperProvider not initialized")
      }
    } catch (e: Exception) {
      promise?.reject("INIT_ERROR", "Failed to initialize payment sheet: ${e.message}")
    }
  }

  override fun presentPaymentSheet(readableMap: ReadableMap, promise: Promise?) {
    try {
      hyperProvider?.let { provider ->
        sheetPromise = promise
        provider.presentPaymentSheet(readableMap)
      }
    } catch (e: Exception) {
      promise?.reject("PRESENT_ERROR", "Failed to present payment sheet: ${e.message}")
    }
  }

  override fun getCustomerSavedPaymentMethods(promise: Promise?) {
    val auth = sdkAuthorization
    if (auth == null) {
      promise?.resolve(
        serializeResult("error", "NO_SESSION", "Payment session not initialized. Call initPaymentSession first.")
      )
      return
    }

    val application = currentActivity?.application
    if (application == null) {
      promise?.resolve(
        serializeResult("error", "NO_ACTIVITY", "Current activity is null. Cannot start headless flow.")
      )
      return
    }

    HeadlessFlowController.getCustomerSavedPaymentMethods(auth, application, callback = { handler ->
      paymentSessionHandler = handler
      promise?.resolve(
        serializeResult("success", null, "Payment methods initialized")
      )
    })
  }

  override fun getCustomerDefaultSavedPaymentMethodData(promise: Promise?) {
    val handler = paymentSessionHandler
    if (handler == null) {
      promise?.resolve(
        serializeResult("error", "UNKNOWN", "Payment session handler not initialized.")
      )
      return
    }

    val result = handler.getCustomerDefaultSavedPaymentMethodData()
    result.fold(
      onSuccess = { pm ->
        promise?.resolve(
          serializeResult("success", null, "Default payment method retrieved", paymentMethodToJson(pm))
        )
      },
      onFailure = { error ->
        val pmError = error as? PMError
        promise?.resolve(
          serializeResult("failed", pmError?.code ?: "UNKNOWN", pmError?.message ?: error.message ?: "Unknown error")
        )
      }
    )
  }

  override fun getCustomerLastUsedPaymentMethodData(promise: Promise?) {
    val handler = paymentSessionHandler
    if (handler == null) {
      promise?.resolve(
        serializeResult("error", "UNKNOWN", "Payment session handler not initialized.")
      )
      return
    }

    val result = handler.getCustomerLastUsedPaymentMethodData()
    result.fold(
      onSuccess = { pm ->
        promise?.resolve(
          serializeResult("success", null, "Last used payment method retrieved", paymentMethodToJson(pm))
        )
      },
      onFailure = { error ->
        val pmError = error as? PMError
        promise?.resolve(
          serializeResult("failed", pmError?.code ?: "UNKNOWN", pmError?.message ?: error.message ?: "Unknown error")
        )
      }
    )
  }

  override fun confirmWithCustomerDefaultPaymentMethod(reactTag: Int, promise: Promise?) {
    val handler = paymentSessionHandler
    if (handler == null) {
      promise?.resolve(
        serializeResult("error", "UNKNOWN", "Payment session handler not initialized.")
      )
      return
    }

    if (reactTag > 0) {
      // CvcWidget reactTag provided — route card confirm through CvcWidget's JS context
      val defaultData = handler.getCustomerDefaultSavedPaymentMethodData()
      defaultData.fold(
        onSuccess = { pm ->
          if (pm.requiresCvv && pm.paymentMethod == PaymentMethodType.CARD) {
            confirmViaWidgetView(reactTag, pm.paymentToken, pm.paymentMethodId, promise)
          } else {
            // Not a card or requiresCvv is false — bypass CvcWidget, confirm directly with cvc = null
            handler.confirmWithCustomerDefaultPaymentMethod(null) { result ->
              promise?.resolve(paymentResultToString(result))
            }
          }
        },
        onFailure = { error ->
          val pmError = error as? PMError
          promise?.resolve(
            serializeResult("failed", pmError?.code ?: "UNKNOWN", pmError?.message ?: error.message ?: "Unknown error")
          )
        }
      )
    } else {
      // No CvcWidget — confirm through HeadlessJsTask's callback (cvc will be null)
      handler.confirmWithCustomerDefaultPaymentMethod(null) { result ->
        promise?.resolve(paymentResultToString(result))
      }
    }
  }

  override fun confirmWithCustomerLastUsedPaymentMethod(reactTag: Int, promise: Promise?) {
    val handler = paymentSessionHandler
    if (handler == null) {
      promise?.resolve(
        serializeResult("error", "NO_HANDLER", "Payment session handler not initialized.")
      )
      return
    }

    if (reactTag > 0) {
      // CvcWidget reactTag provided — route card confirm through CvcWidget's JS context
      val lastUsedData = handler.getCustomerLastUsedPaymentMethodData()

      lastUsedData.fold(
        onSuccess = { pm ->
          if (pm.requiresCvv && pm.paymentMethod == PaymentMethodType.CARD) {
            confirmViaWidgetView(reactTag, pm.paymentToken, pm.paymentMethodId, promise)
          } else {
            // Not a card or requiresCvv is false — bypass CvcWidget, confirm directly with cvc = null
            handler.confirmWithCustomerLastUsedPaymentMethod(null) { result ->
              promise?.resolve(paymentResultToString(result))
            }
          }
        },
        onFailure = { error ->
          val pmError = error as? PMError
          promise?.resolve(
            serializeResult("failed", pmError?.code ?: "UNKNOWN", pmError?.message ?: error.message ?: "Unknown error")
          )
        }
      )
    } else {
      // No CvcWidget — confirm through HeadlessJsTask's callback (cvc will be null)
      handler.confirmWithCustomerLastUsedPaymentMethod(null) { result ->
        promise?.resolve(paymentResultToString(result))
      }
    }
  }

  override fun confirmWithCustomerPaymentToken(paymentToken: String, promise: Promise?) {
    val handler = paymentSessionHandler
    if (handler == null) {
      promise?.resolve(
        serializeResult("error", "UNKNOWN", "Payment session handler not initialized.")
      )
      return
    }

    handler.confirmWithCustomerPaymentToken(paymentToken, null) { result ->
      promise?.resolve(paymentResultToString(result))
    }
  }

  /**
   * Routes a card confirm through CvcWidget's view/fragment by resolving the
   * PaymentWidgetView from the reactTag via UIManagerModule and calling confirmCvcPayment.
   * The fragment emits "triggerWidgetAction" with CONFIRM_CVC_PAYMENT, and the
   * CvcWidget JS bundle handles CVC lookup + confirm API call.
   * Result flows back through exitHeadless → ExitHeadlessCallBackManager → callback → promise.resolve.
   */
  private fun confirmViaWidgetView(
    reactTag: Int,
    paymentToken: String,
    paymentMethodId: String,
    promise: Promise?
  ) {
    val uiManagerModule =
      reactApplicationContext.getNativeModule<UIManagerModule?>(UIManagerModule::class.java)
    uiManagerModule?.addUIBlock { nvhm ->
      try {
        val view = nvhm.resolveView(reactTag)
        if (view is PaymentWidgetView) {
          view.confirmCvcPayment(
            Callback { args ->
              if (args.isNotEmpty()) {
                promise?.resolve(args[0] as? String ?: serializeResult("failed", "UNKNOWN", "Unexpected response"))
              } else {
                promise?.resolve(serializeResult("failed", "UNKNOWN", "Empty response from widget"))
              }
            },
            paymentToken,
            paymentMethodId
          )
        } else {
          promise?.resolve(
            serializeResult("failed", "INVALID_VIEW", "View at reactTag $reactTag is not a CvcWidget")
          )
        }
      } catch (e: IllegalViewOperationException) {
        promise?.resolve(
          serializeResult("failed", "NO_WIDGET", "CvcWidget not found at reactTag $reactTag: ${e.message}")
        )
      }
    }
  }

  fun resetView() {
    hyperProvider?.removeSheetView(true)
  }

  companion object {
    const val NAME = "HyperswitchSdkReactNative"
    private var sheetPromise: Promise? = null
    private var currentInstance: HyperswitchRNWrapperNativeModule? = null
    private var hostReactContext: ReactApplicationContext? = null
    private var sdkAuthorization: String? = null
    @Volatile
    private var paymentSessionHandler: PaymentSessionHandler? = null
    @Volatile
    var isCvcWidgetActive: Boolean = false

    fun resolvePromise(data: Any?) {
      try {
        sheetPromise?.resolve(data)
      } catch (e: Exception) {
      }
    }

    fun resetView() {
      currentInstance?.resetView()
    }

    fun emitPaymentSheetEvent(eventType: String, payload: ReadableMap) {
      try {
        hostReactContext
          ?.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
          ?.emit("onPaymentSheetEvent", Arguments.createMap().apply {
            putString("eventName", eventType)
            putMap("payload", payload)
          })
      } catch (e: Exception) {
      }
    }

    /**
     * Convert HeadlessPaymentResult (Throwable-based Failed) to JSON string.
     * Old pattern: code in throwable.cause.message, message in throwable.message
     */
    private fun paymentResultToString(result: HeadlessPaymentResult): String {
      val json = JSONObject()
      when (result) {
        is HeadlessPaymentResult.Completed -> {
          json.put("status", "success")
          json.put("message", "Payment confirmed successfully")
          json.put("data", result.data)
        }
        is HeadlessPaymentResult.Failed -> {
          json.put("status", "failed")
          json.put("code", result.throwable.cause?.message ?: "UNKNOWN_ERROR")
          json.put("message", result.throwable.message ?: "An error has occurred.")
        }
        is HeadlessPaymentResult.Canceled -> {
          json.put("status", "cancelled")
          json.put("message", "Payment confirmation cancelled")
          json.put("data", result.data)
        }
      }
      return json.toString()
    }

    /**
     * Convert PaymentMethod (common lib type with toMap()) to JSON string for the data field.
     * Uses JSONObject recursively to handle nested maps (e.g., card).
     */
    private fun paymentMethodToJson(pm: com.hyperswitchsdkreactnative.headless.PaymentMethod): String {
      return mapToJsonObject(pm.toMap()).toString()
    }

    private fun mapToJsonObject(map: Map<String, Any?>): JSONObject {
      val json = JSONObject()
      for ((key, value) in map) {
        when (value) {
          is Map<*, *> -> json.put(key, mapToJsonObject(value as Map<String, Any?>))
          is List<*> -> json.put(key, org.json.JSONArray(value))
          null -> json.put(key, JSONObject.NULL)
          else -> json.put(key, value)
        }
      }
      return json
    }

    private fun serializeResult(status: String, code: String?, message: String, data: String? = null): String {
      val json = JSONObject().apply {
        put("status", status)
        if (code != null) put("code", code)
        put("message", message)
        if (data != null) put("data", JSONObject(data))
      }
      return json.toString()
    }
  }
}
