package com.hyperswitchsdkreactnative.modules

import android.util.Log
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.facebook.react.uimanager.IllegalViewOperationException
import com.facebook.react.uimanager.UIManagerModule
import com.hyperswitchsdkreactnative.NativeHyperswitchSdkReactNativeSpec
import io.hyperswitch.model.CustomEndpointConfiguration
import io.hyperswitch.model.HyperswitchConfiguration
import io.hyperswitch.model.HyperswitchEnvironment
import io.hyperswitch.model.OverrideEndpoints
import io.hyperswitch.model.PaymentSessionConfiguration
import io.hyperswitch.paymentsession.PMError
import io.hyperswitch.paymentsession.PaymentMethod
import io.hyperswitch.paymentsession.PaymentMethodType
import io.hyperswitch.paymentsession.PaymentSessionHandler
import io.hyperswitch.paymentsession.SavedPaymentMethodsConfiguration
import io.hyperswitch.paymentsheet.PaymentResult
import io.hyperswitch.sdk.Hyperswitch
import io.hyperswitch.sdk.HyperswitchInstance
import io.hyperswitch.sdk.PaymentSession
import io.hyperswitch.view.HyperswitchElement
import org.json.JSONObject
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap


class HyperswitchRNWrapperNativeModule(reactContext: ReactApplicationContext) :
  NativeHyperswitchSdkReactNativeSpec(reactContext) {

  private val instances = ConcurrentHashMap<String, HyperswitchInstance>()
  private var activePaymentSession: PaymentSession? = null
  private var activePaymentSessionHandler: PaymentSessionHandler? = null

  init {
    currentInstance = this
    hostReactContext = reactContext
  }

  override fun getName(): String {
    return NAME
  }

  override fun initialise(config: ReadableMap?, promise: Promise?) {
    try {
      val activity = currentActivity
      if (activity == null) {
        promise?.reject("INITIALIZATION_ERROR", "Current activity is null")
        return
      }

      val publishableKey = config?.getString("publishableKey")
      if (publishableKey.isNullOrBlank()) {
        promise?.reject("INITIALIZATION_ERROR", "publishableKey is required")
        return
      }

      val profileId = config.getString("profileId")
      val environment = parseEnvironment(config.getString("environment"))
      val customEndpoints = config.getMap("customEndpoints")
      activePublishableKey = publishableKey
      activeProfileId = profileId

      val hsConfig = buildHyperswitchConfiguration(
        publishableKey = publishableKey,
        profileId = profileId,
        customEndpoints = customEndpoints,
        environment = environment
      )

      val instance = Hyperswitch.init(activity, hsConfig)
      val handle = UUID.randomUUID().toString()
      instances[handle] = instance

      promise?.resolve(handle)
    } catch (e: Exception) {
      promise?.reject("INITIALIZATION_ERROR", "Failed to initialize Hyperswitch SDK: ${e.message}")
    }
  }

  override fun initPaymentSession(
    instanceHandle: String?,
    sdkAuthorization: String?,
    promise: Promise?
  ) {
    val instanceHandleNonNull = instanceHandle ?: run {
      promise?.reject("INIT_ERROR", "instanceHandle is required")
      return
    }
    val sdkAuthorizationNonNull = sdkAuthorization ?: run {
      promise?.reject("INIT_ERROR", "sdkAuthorization is required")
      return
    }

    val instance = instances[instanceHandleNonNull]
    if (instance == null) {
      promise?.reject(
        "INIT_ERROR",
        "Hyperswitch instance not found for handle: $instanceHandleNonNull"
      )
      return
    }

    activePaymentSession = null
    activePaymentSessionHandler = null
    activeSdkAuthorization = null

    instance.initPaymentSession(PaymentSessionConfiguration(sdkAuthorizationNonNull)) { session ->
      activePaymentSession = session
      activePaymentSessionHandler = null
      activeSdkAuthorization = sdkAuthorizationNonNull
      promise?.resolve("active")
    }
  }

  override fun presentPaymentSheet(
    configuration: ReadableMap,
    promise: Promise?
  ) {
    val session = activePaymentSession
    if (session == null) {
      promise?.reject(
        "PRESENT_ERROR",
        "Payment session not initialized. Call initPaymentSession first."
      )
      return
    }

    val configMap = readableMapToMap(configuration)
    session.presentPaymentSheet(configMap, null) { result ->
      promise?.resolve(paymentResultToString(result))
    }
  }

  override fun getCustomerSavedPaymentMethods(
    options: ReadableMap?,
    promise: Promise?
  ) {
    val session = activePaymentSession
    if (session == null) {
      promise?.resolve(
        serializeResult(
          "error",
          "NO_SESSION",
          "Payment session not initialized. Call initPaymentSession first."
        )
      )
      return
    }
    val hiddenPaymentMethods = options?.getArray("hiddenPaymentMethods")?.toArrayList()
      ?.filterIsInstance<String>()
      ?: emptyList()

    session.getCustomerSavedPaymentMethods(SavedPaymentMethodsConfiguration(hiddenPaymentMethods)) { handler ->
      activePaymentSessionHandler = handler
      Log.d(NAME, "getCustomerSavedPaymentMethods: handler received")
      promise?.resolve(serializeResult("success", null, "Payment methods initialized"))
    }
  }

  override fun getCustomerDefaultSavedPaymentMethodData(promise: Promise?) {
    val handler = activePaymentSessionHandler
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
          serializeResult(
            "success",
            null,
            "Default payment method retrieved",
            paymentMethodToJson(pm)
          )
        )
      },
      onFailure = { error ->
        val pmError = error as? PMError
        promise?.resolve(
          serializeResult(
            "failed",
            pmError?.code ?: "UNKNOWN",
            pmError?.message ?: error.message ?: "Unknown error"
          )
        )
      }
    )
  }

  override fun getCustomerLastUsedPaymentMethodData(promise: Promise?) {
    val handler = activePaymentSessionHandler
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
          serializeResult(
            "success",
            null,
            "Last used payment method retrieved",
            paymentMethodToJson(pm)
          )
        )
      },
      onFailure = { error ->
        val pmError = error as? PMError
        promise?.resolve(
          serializeResult(
            "failed",
            pmError?.code ?: "UNKNOWN",
            pmError?.message ?: error.message ?: "Unknown error"
          )
        )
      }
    )
  }

  override fun confirmWithCustomerDefaultPaymentMethod(
    cvcWidgetReactTag: String?,
    promise: Promise?
  ) {
    val handler = activePaymentSessionHandler
    if (handler == null) {
      promise?.resolve(
        serializeResult("error", "UNKNOWN", "Payment session handler not initialized.")
      )
      return
    }

    val reactTag = cvcWidgetReactTag?.toIntOrNull() ?: 0

    if (reactTag > 0) {
      val defaultData = handler.getCustomerDefaultSavedPaymentMethodData()
      defaultData.fold(
        onSuccess = { pm ->
          if (pm.requiresCvv && pm.paymentMethod == PaymentMethodType.CARD) {
            confirmViaWidgetView(reactTag, pm.paymentToken, pm.paymentMethodId, promise)
          } else {
            handler.confirmWithCustomerDefaultPaymentMethod(null) { result ->
              promise?.resolve(paymentResultToString(result))
            }
          }
        },
        onFailure = { error ->
          val pmError = error as? PMError
          promise?.resolve(
            serializeResult(
              "failed",
              pmError?.code ?: "UNKNOWN",
              pmError?.message ?: error.message ?: "Unknown error"
            )
          )
        }
      )
    } else {
      handler.confirmWithCustomerDefaultPaymentMethod(null) { result ->
        promise?.resolve(paymentResultToString(result))
      }
    }
  }

  override fun confirmWithCustomerLastUsedPaymentMethod(
    cvcWidgetReactTag: String?,
    promise: Promise?
  ) {
    val handler = activePaymentSessionHandler
    if (handler == null) {
      promise?.resolve(
        serializeResult("error", "UNKNOWN", "Payment session handler not initialized.")
      )
      return
    }

    val reactTag = cvcWidgetReactTag?.toIntOrNull() ?: 0

    if (reactTag > 0) {
      val lastUsedData = handler.getCustomerLastUsedPaymentMethodData()
      lastUsedData.fold(
        onSuccess = { pm ->
          if (pm.requiresCvv && pm.paymentMethod == PaymentMethodType.CARD) {
            confirmViaWidgetView(reactTag, pm.paymentToken, pm.paymentMethodId, promise)
          } else {
            handler.confirmWithCustomerLastUsedPaymentMethod(null) { result ->
              promise?.resolve(paymentResultToString(result))
            }
          }
        },
        onFailure = { error ->
          val pmError = error as? PMError
          promise?.resolve(
            serializeResult(
              "failed",
              pmError?.code ?: "UNKNOWN",
              pmError?.message ?: error.message ?: "Unknown error"
            )
          )
        }
      )
    } else {
      handler.confirmWithCustomerLastUsedPaymentMethod(null) { result ->
        promise?.resolve(paymentResultToString(result))
      }
    }
  }

  override fun confirmWithCustomerPaymentToken(
    paymentToken: String,
    promise: Promise?
  ) {
    val handler = activePaymentSessionHandler
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

  override fun updateIntent(sdkAuthorization: String?, promise: Promise?) {
    val sdkAuthorizationNonNull = sdkAuthorization ?: run {
      promise?.reject("UPDATE_INTENT_ERROR", "sdkAuthorization is required")
      return
    }

    val session = activePaymentSession
    if (session == null) {
      promise?.reject(
        "UPDATE_INTENT_ERROR",
        "Payment session not initialized. Call initPaymentSession first."
      )
      return
    }

    session.updateSdkAuthorization(sdkAuthorizationNonNull)
    activeSdkAuthorization = sdkAuthorizationNonNull

    promise?.resolve(serializeResult("success", null, "Payment intent updated"))
  }

  private fun confirmViaWidgetView(
    reactTag: Int,
    paymentToken: String,
    paymentMethodId: String,
    promise: Promise?
  ) {
    val sdkAuthorization = getActiveSdkAuthorization()
    if (sdkAuthorization.isNullOrEmpty()) {
      promise?.resolve(
        serializeResult("failed", "NO_SESSION", "No active SDK authorization for CVC confirm")
      )
      return
    }

    val uiManagerModule =
      reactApplicationContext.getNativeModule<UIManagerModule?>(UIManagerModule::class.java)
    uiManagerModule?.addUIBlock { nvhm ->
      try {
        val view = nvhm.resolveView(reactTag)
        if (view is HyperswitchElement) {
          view.confirmCVCWidget(sdkAuthorization, paymentToken, paymentMethodId) { result ->
            promise?.resolve(paymentResultToString(result))
          }
        } else {
          promise?.resolve(
            serializeResult(
              "failed",
              "INVALID_VIEW",
              "View at reactTag $reactTag is not a CvcWidget"
            )
          )
        }
      } catch (e: IllegalViewOperationException) {
        promise?.resolve(
          serializeResult(
            "failed",
            "NO_WIDGET",
            "CvcWidget not found at reactTag $reactTag: ${e.message}"
          )
        )
      }
    }
  }

  fun resetView() {
    // PaymentSession manages its own sheet UI; no global provider reset is needed.
  }

  companion object {
    const val NAME = "HyperswitchSdkReactNative"
    private var currentInstance: HyperswitchRNWrapperNativeModule? = null
    private var hostReactContext: ReactApplicationContext? = null
    private var activeSdkAuthorization: String? = null
    private var activePublishableKey: String? = null
    private var activeProfileId: String? = null


    fun getActivePaymentSessionHandler(): PaymentSessionHandler? =
      currentInstance?.activePaymentSessionHandler

    fun getActiveSdkAuthorization(): String? = activeSdkAuthorization

    fun getActivePublishableKey(): String? = activePublishableKey

    fun getActiveProfileId(): String? = activeProfileId

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

    private fun paymentResultToString(result: PaymentResult): String {
      val json = JSONObject()
      when (result) {
        is PaymentResult.Completed -> {
          json.put("status", "success")
          json.put("message", "Payment confirmed successfully")
          json.put("data", result.data)
        }

        is PaymentResult.Failed -> {
          json.put("status", "failed")
          json.put("code", result.throwable.cause?.message ?: "UNKNOWN_ERROR")
          json.put("message", result.throwable.message ?: "An error has occurred.")
        }

        is PaymentResult.Canceled -> {
          json.put("status", "cancelled")
          json.put("message", "Payment confirmation cancelled")
          json.put("data", result.data)
        }
      }
      return json.toString()
    }

    private fun paymentMethodToJson(pm: PaymentMethod): String {
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

    private fun serializeResult(
      status: String,
      code: String?,
      message: String,
      data: String? = null
    ): String {
      val json = JSONObject().apply {
        put("status", status)
        if (code != null) put("code", code)
        put("message", message)
        if (data != null) put("data", JSONObject(data))
      }
      return json.toString()
    }

    private fun parseEnvironment(value: String?): HyperswitchEnvironment {
      return when (value?.lowercase()) {
        "production" -> HyperswitchEnvironment.PROD
        "prod" -> HyperswitchEnvironment.PROD
        else -> HyperswitchEnvironment.SANDBOX
      }
    }

    private fun buildHyperswitchConfiguration(
      publishableKey: String,
      profileId: String?,
      customEndpoints: ReadableMap?,
      environment: HyperswitchEnvironment
    ): HyperswitchConfiguration {
      val overrideEndpointsMap = customEndpoints?.getMap("overrideEndpoints")
      val overrideEndpoints = if (overrideEndpointsMap != null) {
        OverrideEndpoints(
          overrideEndpointsMap.getString("customBackendEndpoint"),
          overrideEndpointsMap.getString("customLoggingEndpoint"),
          overrideEndpointsMap.getString("customAssetEndpoint"),
          overrideEndpointsMap.getString("customSDKConfigEndpoint"),
          null,
          overrideEndpointsMap.getString("customAirborneEndpoint")
        )
      } else {
        OverrideEndpoints()
      }

      val customConfig = CustomEndpointConfiguration(
        overrideEndpoints,
        customEndpoints?.getString("commonEndpoint")
      )

      return HyperswitchConfiguration(
        publishableKey,
        profileId ?: "",
        customConfig,
        environment
      )
    }

    private fun readableMapToMap(map: ReadableMap): Map<String, Any?> {
      val iterator = map.entryIterator
      val result = mutableMapOf<String, Any?>()
      while (iterator.hasNext()) {
        val entry = iterator.next()
        result[entry.key] = when (entry.value) {
          is ReadableMap -> readableMapToMap(entry.value as ReadableMap)
          else -> entry.value
        }
      }
      return result
    }

    private fun bundleToMap(bundle: android.os.Bundle): Map<String, Any?> {
      val result = mutableMapOf<String, Any?>()
      for (key in bundle.keySet()) {
        result[key] = when (val value = bundle.get(key)) {
          is android.os.Bundle -> bundleToMap(value)
          is ArrayList<*> -> value
          else -> value
        }
      }
      return result
    }
  }
}
