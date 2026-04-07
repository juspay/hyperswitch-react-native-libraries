package com.hyperswitchsdkreactnative.modules

import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeMap
import org.json.JSONException
import com.hyperswitchsdkreactnative.NativeHyperswitchSdkNativeSpec
import com.hyperswitchsdkreactnative.modules.HyperswitchRNWrapperNativeModule.Companion.resetView
import com.hyperswitchsdkreactnative.modules.HyperswitchRNWrapperNativeModule.Companion.resolvePromise
import com.hyperswitchsdkreactnative.provider.HyperFragment
import io.hyperswitch.payments.GooglePayCallbackManager

/**
 * HyperModules TurboModule implementation that bridges the bundle's expectations
 * with the existing HyperswitchSdkModule functionality
 */

enum class EventName {
  CONFIRM_PAYMENT_ACTION
}

class HyperswitchSdkNativeModule(reactContext: ReactApplicationContext) :
  NativeHyperswitchSdkNativeSpec(reactContext) {

  override fun getName(): String {
    return NAME
  }

  init {
    reactContextInstance = reactContext
  }


  override fun sendMessageToNative(message: String) {
  }

  override fun launchApplePay(requestObj: String, callback: Callback) {
    callback.invoke("Apple Pay not implemented")
  }

  override fun startApplePay(requestObj: String?, callback: Callback) {
    callback.invoke("Apple Pay not implemented")
  }

  override fun presentApplePay(requestObj: String?, callback: Callback) {
    callback.invoke("Apple Pay not implemented")
  }


  override fun launchGPay(requestObj: String, callback: Callback) {
    GooglePayCallbackManager.setCallback(
      currentActivity ?: reactApplicationContext,
      requestObj,
      fun(data: Map<String, Any?>) {
        callback.invoke(mapToWritableMap(data))
      },
    )
  }

  override fun exitPaymentsheet(rootTag: Double, result: String, reset: Boolean) {
    try {
      resolvePromise(result)
      resetView()
    } catch (_: JSONException) {
      resolvePromise(result)
    }
  }

  override fun exitPaymentMethodManagement(rootTag: Double, result: String, reset: Boolean) {
    try {
      resolvePromise(result)
      resetView()
    } catch (_: JSONException) {
      resolvePromise(result)
    }
  }


  override fun notifyWidgetPaymentResult(rootTag: Int, result: String) {
    try {
      HyperFragment.resolveConfirmPayment(rootTag, result)
    } catch (_: Exception) {
      Log.i("HyperModule", "Error in notifyWidgetPaymentResult")
    }
  }

  override fun exitWidget(result: String, widgetType: String) {
    try {
      resolvePromise(result)
      resetView()
    } catch (e: JSONException) {
      resolvePromise(result)
    }
  }

  override fun exitCardForm(result: String) {
    try {
      resolvePromise(result)
      resetView()
    } catch (e: JSONException) {
      resolvePromise(result)
    }
  }

  override fun exitWidgetPaymentsheet(
    rootTag: Double,
    result: String,
    reset: Boolean
  ) {
    HyperFragment.onPaymentResultEvent(rootTag.toInt(), result)
  }

  override fun launchWidgetPaymentSheet(requestObj: String, callback: Callback) {
    callback.invoke("Widget payment sheet not implemented")
  }

  override fun updateWidgetHeight(height: Double) {
  }

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


  override fun addListener(eventName: String?) {

  }

  override fun removeListeners(count: Double?) {
  }


  companion object {
    const val NAME = "HyperModule"
    private var reactContextInstance: ReactContext? = null
  }
}
