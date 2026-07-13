package com.hyperswitchsdkreactnative.modules

import android.view.View
import android.view.ViewGroup
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.IllegalViewOperationException
import com.facebook.react.uimanager.UIManagerModule
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import com.hyperswitchsdkreactnative.NativePaymentWidgetNativeSpec
import io.hyperswitch.model.ElementUpdateIntentResult
import io.hyperswitch.paymentsheet.PaymentResult
import io.hyperswitch.view.HyperswitchElement

class NativePaymentWidgetNativeModule(reactContext: ReactApplicationContext) :
  NativePaymentWidgetNativeSpec(reactContext) {

  private val moduleScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

  override fun invalidate() {
    moduleScope.cancel()
    super.invalidate()
  }

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
        val element = resolveHyperswitchElement(view)
        if (element != null) {
          element.confirmPayment { result ->
            callback.invoke(paymentResultToMap(result))
          }
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
        val element = resolveHyperswitchElement(view)
        if (element != null) {
          element.updateIntentInit {
            callback.invoke(Arguments.createMap().apply { putString("status", "success") })
          }
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
        val element = resolveHyperswitchElement(view)
        if (element != null) {
          moduleScope.launch {
            try {
              val result = element.updateIntentComplete(sdkAuthorization)
              callback.invoke(updateIntentResultToMap(result))
            } catch (e: Exception) {
              callback.invoke("ERROR", "updateIntentComplete failed: ${e.message}")
            }
          }
        } else {
          callback.invoke("ERROR", "Invalid view type")
        }
      } catch (e: IllegalViewOperationException) {
        callback.invoke("ERROR", "View not found: ${e.message}")
      }
    }
  }

  private fun paymentResultToMap(result: PaymentResult): ReadableMap {
    val map = Arguments.createMap()
    when (result) {
      is PaymentResult.Completed -> {
        map.putString("status", "success")
        map.putString("message", "Payment confirmed successfully")
        result.data?.let { map.putString("data", it) }
      }

      is PaymentResult.Failed -> {
        map.putString("status", "failed")
        map.putString("code", result.throwable.cause?.message ?: "UNKNOWN_ERROR")
        map.putString("message", result.throwable.message ?: "An error has occurred.")
      }

      is PaymentResult.Canceled -> {
        map.putString("status", "cancelled")
        map.putString("message", "Payment confirmation cancelled")
        result.data?.let { map.putString("data", it) }
      }
    }
    return map
  }

  private fun resolveHyperswitchElement(view: View?): HyperswitchElement? {
    if (view == null) return null
    if (view is HyperswitchElement) return view
    if (view is ViewGroup) {
      try {
        return view.getChildAt(0) as HyperswitchElement?
      } catch (_: Exception) {
        for (i in 0 until view.childCount) {
          val child = view.getChildAt(i)
          resolveHyperswitchElement(child)?.let {
            return it
          }
        }
      }
    }
    return null
  }

  private fun updateIntentResultToMap(result: ElementUpdateIntentResult): ReadableMap {
    val map = Arguments.createMap()
    when (result) {
      is ElementUpdateIntentResult.Success -> {
        map.putString("status", "success")
        map.putString("message", "Update intent completed")
      }

      is ElementUpdateIntentResult.Cancelled -> {
        map.putString("status", "cancelled")
        map.putString("message", "Update intent cancelled")
      }

      is ElementUpdateIntentResult.Failure -> {
        map.putString("status", "failed")
        map.putString("code", result.cause.message ?: "UNKNOWN_ERROR")
        map.putString("message", result.cause.localizedMessage ?: "Update intent failed")
      }
    }
    return map
  }

  companion object {
    const val NAME = "NativePaymentWidget"
  }
}
