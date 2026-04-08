package com.hyperswitchsdkreactnative.modules

import android.util.Log
import androidx.fragment.app.FragmentManager
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeMap
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.IllegalViewOperationException
import com.facebook.react.uimanager.UIManagerModule
import org.json.JSONException
import com.hyperswitchsdkreactnative.NativeHyperswitchSdkNativeSpec
import com.hyperswitchsdkreactnative.modules.HyperswitchRNWrapperNativeModule.Companion.resetView
import com.hyperswitchsdkreactnative.modules.HyperswitchRNWrapperNativeModule.Companion.resolvePromise
import com.hyperswitchsdkreactnative.provider.CallbackType
import com.hyperswitchsdkreactnative.provider.HyperFragment
import io.hyperswitch.payments.GooglePayCallbackManager

/**
 * HyperModules TurboModule implementation that bridges the bundle's expectations
 * with the existing HyperswitchSdkModule functionality
 */

enum class EventName {
  CONFIRM_PAYMENT_ACTION,
  CONFIRM_CVC_PAYMENT
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

  private fun findFragmentWithRootTag(rootTag: Int, onFound: (HyperFragment?) -> Unit) {
    val uiManagerModule =
      reactApplicationContext.getNativeModule<UIManagerModule?>(UIManagerModule::class.java)

    if (uiManagerModule == null) {
      onFound(null)
      return
    }

    uiManagerModule.addUIBlock { nvhm ->
      try {
        val reactRootView = nvhm.resolveView(rootTag)
        onFound(FragmentManager.findFragment<HyperFragment>(reactRootView))
      } catch (e: IllegalViewOperationException) {
        onFound(null)
      } catch (e: Exception) {
        onFound(null)
      }
    }
  }

  override fun notifyWidgetPaymentResult(rootTag: Int, result: String) {
    try {
      findFragmentWithRootTag(rootTag, {
        it?.notifyResult(CallbackType.CONFIRM_ACTION, result)
      })
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
    findFragmentWithRootTag(rootTag.toInt(), {
      it?.notifyResult(CallbackType.PAYMENT_RESULT, result)
    })
  }

  override fun launchWidgetPaymentSheet(requestObj: String, callback: Callback) {
    callback.invoke("Widget payment sheet not implemented")
  }

  override fun updateWidgetHeight(height: Double) {
  }

  override fun onAddPaymentMethod(data: String) {
  }


  @ReactMethod
  override fun emitPaymentEvent(rootTag: Int, eventType: String, payload: ReadableMap) {
    try {
      if (rootTag <= 0) {
        HyperswitchRNWrapperNativeModule.emitPaymentSheetEvent(eventType, payload)
      } else {
        findFragmentWithRootTag(rootTag, {
          it?.notifyEvent(eventType, payload)
        })
      }
    } catch (e: Exception) {
      Log.e("HyperModule", "Error emitting payment event", e)
    }
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
