package com.reactnativehyperswitchscancard

import androidx.fragment.app.FragmentActivity
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.annotations.ReactModule
import io.hyperswitch.scancard.NativeHyperswitchScancardSpec
import io.hyperswitch.scancard.ScanCardCallback
import io.hyperswitch.scancard.ScanCardManager

@ReactModule(name = HyperswitchScancardModule.NAME)
class HyperswitchScancardModule(reactContext: ReactApplicationContext) :
    NativeHyperswitchScancardSpec(reactContext) {

  override fun getName(): String {
    return NAME
  }

  override fun launchScanCard(scanCardRequest: String, callback: Callback) {
    (currentActivity as? FragmentActivity)?.let {
      ScanCardManager.launch(it, object : ScanCardCallback {
        override fun onScanResult(result: Map<String, Any?>) {
          val data = (result["data"] as? Map<*, *>)?.let { map ->
            map.entries.associate { (k, v) ->
              k.toString() to v?.toString()
            }
          } ?: mapOf()
          val pan = data["pan"] ?: ""
          val expiryMonth = data["expiryMonth"] ?: ""
          val expiryYear = data["expiryYear"] ?: ""

          val dataMap = Arguments.createMap()
          dataMap.putString("pan", pan)
          dataMap.putString("expiryMonth", expiryMonth)
          dataMap.putString("expiryYear", expiryYear)

          val map = Arguments.createMap()
          map.putString("status", result["status"] as String? ?: "Failed")
          map.putMap("data", dataMap)
          callback.invoke(map)
        }
      })
    }
  }
  companion object{
    const val NAME = "HyperswitchScancard"
  }
}
