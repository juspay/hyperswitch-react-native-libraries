package com.reactnativehyperswitchscancard

import com.facebook.react.BaseReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider
class HyperswitchScancardPackage : BaseReactPackage() {

  override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? {
    return when (name) {
      HyperswitchScancardModule.NAME -> HyperswitchScancardModule(reactContext)
      else -> null
    }
  }

  override fun getReactModuleInfoProvider(): ReactModuleInfoProvider {
    return ReactModuleInfoProvider {
      mapOf(
        HyperswitchScancardModule.NAME to ReactModuleInfo(
          HyperswitchScancardModule.NAME,
          HyperswitchScancardModule.NAME,
          false,
          false,
          false,
          true,
        )
      )
    }
  }
}
