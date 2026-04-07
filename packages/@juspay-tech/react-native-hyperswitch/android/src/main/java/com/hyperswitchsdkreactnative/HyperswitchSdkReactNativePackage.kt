package com.hyperswitchsdkreactnative

import com.facebook.react.BaseReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider
import com.facebook.react.uimanager.ViewManager
import com.hyperswitchsdkreactnative.headless.HyperHeadlessModule
import com.hyperswitchsdkreactnative.modules.HyperswitchSdkNativeModule
import com.hyperswitchsdkreactnative.modules.HyperswitchRNWrapperNativeModule
import com.hyperswitchsdkreactnative.modules.NativePaymentWidgetNativeModule
import com.hyperswitchsdkreactnative.views.GooglePayButtonViewManager
import com.hyperswitchsdkreactnative.views.PaymentWidgetViewManager
import java.util.ArrayList

class HyperswitchSdkReactNativePackage : BaseReactPackage() {
  override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? {
    return when (name) {
      HyperswitchRNWrapperNativeModule.NAME -> HyperswitchRNWrapperNativeModule(reactContext)
      HyperswitchSdkNativeModule.NAME -> HyperswitchSdkNativeModule(reactContext)
      NativePaymentWidgetNativeModule.NAME -> NativePaymentWidgetNativeModule(reactContext)
      HyperHeadlessModule.NAME -> HyperHeadlessModule(reactContext)
      else -> null
    }
  }

  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
    val viewManagers: MutableList<ViewManager<*, *>> = ArrayList()
    viewManagers.add(GooglePayButtonViewManager())
    viewManagers.add(PaymentWidgetViewManager())
    return viewManagers
  }

  override fun getReactModuleInfoProvider(): ReactModuleInfoProvider {
    return ReactModuleInfoProvider {
      arrayOf(
        HyperswitchRNWrapperNativeModule.NAME,
        HyperswitchSdkNativeModule.NAME,
        NativePaymentWidgetNativeModule.NAME
      , HyperHeadlessModule.NAME).associateWith {
        ReactModuleInfo(it, it, false, false, false, true)
      }.toMutableMap()
    }
  }
}
