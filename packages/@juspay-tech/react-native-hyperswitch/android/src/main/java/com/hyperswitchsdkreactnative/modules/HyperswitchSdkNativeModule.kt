package com.hyperswitchsdkreactnative.modules

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeMap
import org.json.JSONException
import com.hyperswitchsdkreactnative.NativeHyperswitchSdkNativeSpec
import com.hyperswitchsdkreactnative.modules.HyperswitchSdkReactNativeModule.Companion.resetView
import com.hyperswitchsdkreactnative.modules.HyperswitchSdkReactNativeModule.Companion.resolvePromise
import com.hyperswitchsdkreactnative.utils.WidgetCallbackManager
import io.hyperswitch.payments.GooglePayCallbackManager
/**
 * HyperModules TurboModule implementation that bridges the bundle's expectations
 * with the existing HyperswitchSdkModule functionality
 */
class HyperswitchSdkNativeModule(reactContext: ReactApplicationContext) :
  NativeHyperswitchSdkNativeSpec(reactContext) {

  override fun getName(): String {
    return NAME
  }

  @ReactMethod
  override fun sendMessageToNative(message: String) {
//    Log.d(NAME, "sendMessageToNative called with: $message")
  }

  @ReactMethod
  override fun launchApplePay(requestObj: String, callback: Callback) {
//    Log.d(NAME, "launchApplePay called")
    callback.invoke("Apple Pay not implemented")
  }

  override fun startApplePay(
    requestObj: String?,
    callback: Callback
  ) {
    callback.invoke("Apple Pay not implemented")
  }

  override fun presentApplePay(
    requestObj: String?,
    callback: Callback
  ) {
    callback.invoke("Apple Pay not implemented")
  }


  @ReactMethod
  override fun launchGPay(requestObj: String, callback: Callback) {
    currentActivity?.let {
      GooglePayCallbackManager.setCallback(
        it,
        requestObj,
        fun(data: Map<String, Any?>) {
          callback.invoke(mapToWritableMap(data))
        },
      )
    } ?: run {
      GooglePayCallbackManager.setCallback(
        reactApplicationContext,
        requestObj,
        fun(data: Map<String, Any?>) {
          callback.invoke(mapToWritableMap(data))
        },
      )
    }
  }

  @ReactMethod
  override fun exitPaymentsheet(rootTag: Double, result: String, reset: Boolean) {
    try {
      resolvePromise(result)
      resetView()
    } catch (e: JSONException) {
      resolvePromise(result)
    }

  }

  @ReactMethod
  override fun exitPaymentMethodManagement(rootTag: Double, result: String, reset: Boolean) {
    try {
      resolvePromise(result)
      resetView()
    } catch (e: JSONException) {
      resolvePromise(result)
    }
  }

  @ReactMethod
  override fun exitWidget(result: String, widgetType: String) {
    try {
      resolvePromise(result)
      resetView()
    } catch (e: JSONException) {
      resolvePromise(result)
    }
  }

  @ReactMethod
  override fun exitCardForm(result: String) {
    try {
      resolvePromise(result)
      resetView()
    } catch (e: JSONException) {
      resolvePromise(result)
    }
  }

  @ReactMethod
  override fun exitWidgetPaymentsheet(rootTag: Double, widgetId: String,  result: String, reset: Boolean) {
    try {
      // Use WidgetCallbackManager to send the payment result back to the React Native view
      WidgetCallbackManager.executeCallback(result, widgetId)
//      resolvePromise(result)
//      resetView()
    } catch (e: JSONException) {
      // Try to execute callback even on JSON parse error
      WidgetCallbackManager.executeCallback(result, widgetId)
//      resolvePromise(result)
    }
  }

  @ReactMethod
  override fun launchWidgetPaymentSheet(requestObj: String, callback: Callback) {
    callback.invoke("Widget payment sheet not implemented")
  }

  @ReactMethod
  override fun updateWidgetHeight(height: Double) {
  }

  @ReactMethod
  override fun onAddPaymentMethod(data: String) {
  }



  private fun mapToWritableMap(map: Map<String, Any?>): WritableMap {
    val writableMap = WritableNativeMap()
    for ((key, value) in map) {
      when (value) {
        null -> writableMap.putNull(key)
        is Boolean -> writableMap.putBoolean(key, value)
        is Double -> writableMap.putDouble(key, value)
        is Int -> writableMap.putInt(key, value)
        is String -> writableMap.putString(key, value)
        is Map<*, *> -> writableMap.putMap(key, mapToWritableMap(value as Map<String, Any?>))
        else -> writableMap.putString(key, value.toString())
      }
    }
    return writableMap
  }

  companion object {
    const val NAME = "HyperModule"
  }
}
