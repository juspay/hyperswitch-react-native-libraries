package io.hyperswitch.react

import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.hyperswitchsdkreactnative.NativeHyperHeadlessSpec
import io.hyperswitch.paymentsession.ExitHeadlessCallBackManager
import io.hyperswitch.paymentsession.GetPaymentSessionCallBackManager
import io.hyperswitch.paymentsession.PaymentSessionHandlerImpl

class HyperHeadlessModule internal constructor(private val rct: ReactApplicationContext) :
    NativeHyperHeadlessSpec(rct) {
    override fun getName(): String = NAME

    @ReactMethod
    override  fun getPaymentSession(
        rootTag: Double,
        getPaymentMethodData: ReadableMap,
        getPaymentMethodData2: ReadableMap,
        getPaymentMethodDataArray: ReadableArray,
        callback: Callback
    ) {
        val handler = PaymentSessionHandlerImpl(
            sdkAuthorization = GetPaymentSessionCallBackManager.getSdkAuthorization(),
            defaultMethodData = getPaymentMethodData,
            lastUsedMethodData = getPaymentMethodData2,
            allMethodsData = getPaymentMethodDataArray,
            jsCallback = callback,
        )
      GetPaymentSessionCallBackManager.executeCallback(handler)
    }

    @ReactMethod
    override fun exitHeadless(rootTag: Double, status: String) {
      try {
        ExitHeadlessCallBackManager.executeCallback(rootTag.toInt(), status)
      }catch (_: Exception){
      }
    }

  companion object {
    const val NAME = "HyperHeadless"
  }
}
