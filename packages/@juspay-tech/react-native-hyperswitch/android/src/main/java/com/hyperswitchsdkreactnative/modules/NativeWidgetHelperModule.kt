package com.hyperswitchsdkreactnative.modules

import android.util.Log
import android.view.View
import android.view.ViewGroup
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.UiThreadUtil
import com.facebook.react.uimanager.IllegalViewOperationException
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.UIManagerModule
import com.facebook.react.uimanager.common.UIManagerType
import com.hyperswitchsdkreactnative.BuildConfig
import com.hyperswitchsdkreactnative.NativeWidgetHelperModuleSpec
import io.hyperswitch.view.PaymentWidgetView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

class NativeWidgetHelperModule(reactContext: ReactApplicationContext) :
  NativeWidgetHelperModuleSpec(reactContext) {

  private val moduleScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
  private val uiManagerType = if (BuildConfig.IS_NEW_ARCHITECTURE_ENABLED) {
    UIManagerType.FABRIC
  } else {
    UIManagerType.DEFAULT
  }

  override fun invalidate() {
    moduleScope.cancel()
    super.invalidate()
  }

  override fun getName(): String {
    return NAME
  }

  override fun confirmPayment(
    reactTag: Double,
    callback: Callback
  ) {
    UiThreadUtil.runOnUiThread {
      val uiManagerModule =
        UIManagerHelper.getUIManager(
          reactApplicationContext,
          uiManagerType
        )
      try {
        val view = uiManagerModule?.resolveView(reactTag.toInt())
        val element = resolveHyperswitchElement(view)
        if (element != null) {
          element.confirmPayment { result ->
            callback.invoke(result)
          }
        } else {
          callback.invoke("ERROR", "Invalid view type")
        }
      } catch (e: Exception) {
        callback.invoke("ERROR", "View not found: ${e.message}")
      }
    }
  }

  override fun updateIntentInitForWidget(
    reactTag: Double,
    callback: Callback
  ) {
    val uiManagerModule =
      reactApplicationContext.getNativeModule(UIManagerModule::class.java)
    uiManagerModule?.addUIBlock { nvhm ->
      try {
        val view = nvhm.resolveView(reactTag.toInt())
//        val element = resolveHyperswitchElement(view)
//        if (element != null) {
////          element.updateIntentInit {
////            callback.invoke(Arguments.createMap().apply { putString("status", "success") })
////          }
//        } else {
//          callback.invoke("ERROR", "Invalid view type")
//        }
      } catch (e: IllegalViewOperationException) {
        callback.invoke("ERROR", "View not found: ${e.message}")
      }
    }
  }

  override fun updateIntentCompleteForWidget(
    reactTag: Double,
    sdkAuthorization: String?,
    callback: Callback
  ) {
    val uiManagerModule =
      UIManagerHelper.getUIManager(
        reactApplicationContext,
        uiManagerType
      )
    try {
      val view = uiManagerModule?.resolveView(reactTag.toInt())
//        val element = resolveHyperswitchElement(view)
//        if (element != null) {
//          moduleScope.launch {
//            try {
////              val result = element.updateIntentComplete(sdkAuthorization)
////              callback.invoke(updateIntentResultToMap(result))
//            } catch (e: Exception) {
//              callback.invoke("ERROR", "updateIntentComplete failed: ${e.message}")
//            }
//          }
//        } else {
//          callback.invoke("ERROR", "Invalid view type")
//        }
    } catch (e: IllegalViewOperationException) {
      callback.invoke("ERROR", "View not found: ${e.message}")
    }
  }


//  private fun paymentResultToMap(result: PaymentResult): ReadableMap {
//    val map = Arguments.createMap()
//    when (result) {
//      is PaymentResult.Completed -> {
//        map.putString("status", "success")
//        map.putString("message", "Payment confirmed successfully")
//        result.data?.let { map.putString("data", it) }
//      }
//
//      is PaymentResult.Failed -> {
//        map.putString("status", "failed")
//        map.putString("code", result.throwable.cause?.message ?: "UNKNOWN_ERROR")
//        map.putString("message", result.throwable.message ?: "An error has occurred.")
//      }
//
//      is PaymentResult.Canceled -> {
//        map.putString("status", "cancelled")
//        map.putString("message", "Payment confirmation cancelled")
//        result.data?.let { map.putString("data", it) }
//      }
//    }
//    return map
//  }

  private fun resolveHyperswitchElement(view: View?): PaymentWidgetView? {
    if (view == null) return null
    if (view is PaymentWidgetView) return view
    if (view is ViewGroup) {
      try {
        return view.getChildAt(0) as PaymentWidgetView?
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

//  private fun updateIntentResultToMap(result: ElementUpdateIntentResult): ReadableMap {
//    val map = Arguments.createMap()
//    when (result) {
//      is ElementUpdateIntentResult.Success -> {
//        map.putString("status", "success")
//        map.putString("message", "Update intent completed")
//      }
//
//      is ElementUpdateIntentResult.Cancelled -> {
//        map.putString("status", "cancelled")
//        map.putString("message", "Update intent cancelled")
//      }
//
//      is ElementUpdateIntentResult.Failure -> {
//        map.putString("status", "failed")
//        map.putString("code", result.cause.message ?: "UNKNOWN_ERROR")
//        map.putString("message", result.cause.localizedMessage ?: "Update intent failed")
//      }
//    }
//    return map
//  }

  companion object {
    const val NAME = "NativeWidgetHelperModule"
  }
}
