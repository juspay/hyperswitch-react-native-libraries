package com.hyperswitchsdkreactnative

import com.facebook.react.BaseReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider
import com.facebook.react.uimanager.ViewManager
import com.hyperswitchsdkreactnative.modules.HyperswitchRNWrapperNativeModule
import com.hyperswitchsdkreactnative.modules.NativePaymentWidgetNativeModule
import com.hyperswitchsdkreactnative.views.PaymentElementViewManager
import io.hyperswitch.react.GooglePayButtonManager
import io.hyperswitch.react.HyperHeadlessModule
import io.hyperswitch.react.HyperModule
import java.util.ArrayList

class HyperswitchSdkReactNativePackage : BaseReactPackage() {
  override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? {
    return when (name) {
      HyperswitchRNWrapperNativeModule.NAME -> HyperswitchRNWrapperNativeModule(reactContext)
      HyperModule.NAME -> HyperModule(reactContext)
      HyperHeadlessModule.NAME -> HyperHeadlessModule(reactContext)
      NativePaymentWidgetNativeModule.NAME -> NativePaymentWidgetNativeModule(reactContext)
      else -> null
    }
  }

  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
    val viewManagers: MutableList<ViewManager<*, *>> = ArrayList()
    viewManagers.add(GooglePayButtonManager())
    viewManagers.add(PaymentElementViewManager())
    return viewManagers
  }

  override fun getReactModuleInfoProvider(): ReactModuleInfoProvider {
    return ReactModuleInfoProvider {
      arrayOf(
        HyperswitchRNWrapperNativeModule.NAME,
        HyperModule.NAME,
        HyperHeadlessModule.NAME,
        NativePaymentWidgetNativeModule.NAME,
      ).associateWith {
        ReactModuleInfo(it, it, false, false, false, true)
      }.toMutableMap()
    }
  }
}
