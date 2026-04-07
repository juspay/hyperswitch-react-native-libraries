package com.hyperswitchsdkreactnative.modules

import android.util.Log
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.IllegalViewOperationException
import com.facebook.react.uimanager.NativeViewHierarchyManager
import com.facebook.react.uimanager.UIBlock
import com.facebook.react.uimanager.UIManagerModule
import com.facebook.react.uimanager.ViewManager
import com.hyperswitchsdkreactnative.NativeHyperswitchSdkReactNativeSpec
import com.hyperswitchsdkreactnative.provider.HyperProvider
import com.hyperswitchsdkreactnative.views.PaymentWidgetView


class HyperswitchSdkReactNativeModule(reactContext: ReactApplicationContext) :
  NativeHyperswitchSdkReactNativeSpec(reactContext) {

  private var hyperProvider: HyperProvider? = null

  init {
    currentInstance = this
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

  override fun confirmPayment(reactTag: Int, callback: Callback) {
    Log.i("Manideep", reactTag.toString())
    val uiManagerModule =
      reactApplicationContext.getNativeModule<UIManagerModule?>(UIManagerModule::class.java)
    uiManagerModule?.addUIBlock { nvhm ->
      try {
        val view = nvhm.resolveView(reactTag)
        if (view is PaymentWidgetView) {
          val resultCallback = { it : Any ->
            callback.invoke(it)
            resetView()
          }
          view.confirmPayment(callback)
        } else {
          callback.invoke("ERROR", "Invalid view type")
        }
      } catch (e: IllegalViewOperationException) {
        callback.invoke("ERROR", "View not found: ${e.message}")
      }
    }
  }

  fun resetView() {
    hyperProvider?.removeSheetView(true)
  }

  companion object {
    const val NAME = "HyperswitchSdkReactNative"
    private var sheetPromise: Promise? = null
    private var currentInstance: HyperswitchSdkReactNativeModule? = null

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
