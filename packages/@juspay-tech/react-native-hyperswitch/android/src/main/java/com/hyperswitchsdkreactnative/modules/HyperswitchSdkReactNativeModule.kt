package com.hyperswitchsdkreactnative.modules

import android.util.Log
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.hyperswitchsdkreactnative.NativeHyperswitchSdkReactNativeSpec
import com.hyperswitchsdkreactnative.provider.HyperProvider
import com.hyperswitchsdkreactnative.utils.WidgetCallbackManager
import org.json.JSONObject

class HyperswitchSdkReactNativeModule(reactContext: ReactApplicationContext) :
  NativeHyperswitchSdkReactNativeSpec(reactContext) {

  private var hyperProvider: HyperProvider? = null

  init {
    currentInstance = this
    reactContextInstance = reactContext
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

  override fun initPaymentSession(paymentIntentClientSecret: String, promise: Promise?) {
    try {
      hyperProvider?.let { provider ->
        provider.initPaymentSession(clientSecret = paymentIntentClientSecret)
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

  override fun goBack(widgetId: String) {
    try {
      val eventData = Arguments.createMap()
      eventData.putString("widgetId", widgetId)
      eventData.putString("actionType", "goBack")
      HyperswitchSdkNativeModule.emitEventToJS("triggerWidgetAction", eventData)
    } catch (e: Exception) {
    }
  }

  override fun confirmPayment(widgetId: String, promise: Promise) {
    try {
      val eventData = Arguments.createMap()
      eventData.putString("widgetId", widgetId)
      eventData.putString("actionType", "confirmPayment")
      WidgetCallbackManager.setConfirmPromise(widgetId, promise)
      HyperswitchSdkNativeModule.emitEventToJS("triggerWidgetAction", eventData)
    } catch (e: Exception) {
      promise.reject("CONFIRM_ERROR", "Failed to trigger confirmPayment: ${e.message}")
    }
  }

  @ReactMethod
  fun addListener(eventName: String) {
    // Keep: Required for RN built-in Event Emitter
  }

  @ReactMethod
  fun removeListeners(count: Double) {
    // Keep: Required for RN built-in Event Emitter
  }

  fun resetView() {
    hyperProvider?.removeSheetView(true)
  }

  companion object {
    const val NAME = "HyperswitchSdkReactNative"
    private var sheetPromise: Promise? = null
    private var currentInstance: HyperswitchSdkReactNativeModule? = null
    private var reactContextInstance: ReactApplicationContext? = null

    fun emitEventToJS(eventName: String, data: Any) {
      try {
        reactContextInstance
          ?.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
          ?.emit(eventName, data)
      } catch (_: Exception) {
      }
    }

    fun resolvePromise(data: Any?) {
      try {
        sheetPromise?.resolve(data)
      } catch (e: Exception) {
      }
    }
    fun resetView() {
      currentInstance?.resetView()
    }
  }
}
