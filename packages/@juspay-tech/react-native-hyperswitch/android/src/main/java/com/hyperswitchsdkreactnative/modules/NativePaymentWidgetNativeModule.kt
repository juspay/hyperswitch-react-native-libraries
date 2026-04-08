package com.hyperswitchsdkreactnative.modules

import android.util.Log
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.IllegalViewOperationException
import com.facebook.react.uimanager.UIManagerModule
import com.hyperswitchsdkreactnative.NativePaymentWidgetNativeSpec
import com.hyperswitchsdkreactnative.views.PaymentWidgetView

class NativePaymentWidgetNativeModule(reactContext: ReactApplicationContext) :
  NativePaymentWidgetNativeSpec(reactContext) {

  override fun getName(): String {
    return NAME
  }

  override fun confirmPayment(
    reactTag: Int,
    callback: Callback
  ) {
    val uiManagerModule =
      reactApplicationContext.getNativeModule<UIManagerModule?>(UIManagerModule::class.java)
    uiManagerModule?.addUIBlock { nvhm ->
      try {
        val view = nvhm.resolveView(reactTag)
        if (view is PaymentWidgetView) {
          view.confirmPayment(callback)
        } else {
          callback.invoke("ERROR", "Invalid view type")
        }
      } catch (e: Exception) {
        callback.invoke("ERROR", "View not found: ${e.message}")
      }
    }
  }

  override fun updateIntentInitForWidget(rootTag: Int, callback: Callback) {
    val uiManagerModule =
      reactApplicationContext.getNativeModule<UIManagerModule?>(UIManagerModule::class.java)
    uiManagerModule?.addUIBlock { nvhm ->
      try {
        val view = nvhm.resolveView(rootTag)
        if (view is PaymentWidgetView) {
          view.updatePaymentIntentInit(callback)
        } else {
          callback.invoke("ERROR", "Invalid view type")
        }
      } catch (e: IllegalViewOperationException) {
        callback.invoke("ERROR", "View not found: ${e.message}")
      }
    }
  }

  override fun updateIntentCompleteForWidget(
    rootTag: Int,
    sdkAuthorization: String,
    callback: Callback
  ) {
    val uiManagerModule =
      reactApplicationContext.getNativeModule<UIManagerModule?>(UIManagerModule::class.java)
    uiManagerModule?.addUIBlock { nvhm ->
      try {
        val view = nvhm.resolveView(rootTag)
        if (view is PaymentWidgetView) {
          view.updatePaymentIntentComplete(sdkAuthorization, callback)
        } else {
          callback.invoke("ERROR", "Invalid view type")
        }
      } catch (e: IllegalViewOperationException) {
        callback.invoke("ERROR", "View not found: ${e.message}")
      }
    }
  }

  companion object {
    const val NAME = "NativePaymentWidget"
  }
}
