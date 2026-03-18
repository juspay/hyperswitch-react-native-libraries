package com.juspaytech.reactnativehyperswitchpaypal

import android.util.Log
import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class ReactNativeHyperswitchPaypalPackage : ReactPackage {
  override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
    Log.d("PAYPAL_DEBUG", "[ReactNativeHyperswitchPaypalPackage]: createNativeModules called")
    Log.d("PAYPAL_DEBUG", "[ReactNativeHyperswitchPaypalPackage]: Creating HyperswitchPaypal module")
    return listOf(ReactNativeHyperswitchPaypalModule(reactContext))
  }

  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
    Log.d("PAYPAL_DEBUG", "[ReactNativeHyperswitchPaypalPackage]: createViewManagers called")
    Log.d("PAYPAL_DEBUG", "[ReactNativeHyperswitchPaypalPackage]: Creating PaypalButtonViewManager")
    return listOf(PaypalButtonViewManager())
  }
}
