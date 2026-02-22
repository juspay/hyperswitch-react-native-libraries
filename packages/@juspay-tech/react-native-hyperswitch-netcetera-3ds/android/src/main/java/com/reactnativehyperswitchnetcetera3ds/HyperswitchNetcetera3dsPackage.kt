package com.reactnativehyperswitchnetcetera3ds

import com.facebook.react.BaseReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider

class HyperswitchNetcetera3dsPackage : BaseReactPackage() {

  override fun getModule(
    name: String,
    reactContext: ReactApplicationContext
  ): NativeModule? {
    return when (name) {
      HyperswitchNetcetera3dsModule.NAME -> HyperswitchNetcetera3dsModule(reactContext)
      else -> null
    }
  }

  override fun getReactModuleInfoProvider(): ReactModuleInfoProvider {
    return ReactModuleInfoProvider {
      mapOf(
        HyperswitchNetcetera3dsModule.NAME to ReactModuleInfo(
          HyperswitchNetcetera3dsModule.NAME,
          HyperswitchNetcetera3dsModule.NAME,
          false,
          needsEagerInit = false,
          isCxxModule = false,
          isTurboModule = true,
        )
      )
    }
  }
}
