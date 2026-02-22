package com.reactnativehyperswitchnetcetera3ds

import android.app.Activity
import android.app.Application
import android.util.Log
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.module.annotations.ReactModule
import io.hyperswitch.netcetera3ds.NativeHyperswitchNetceteraSpec

@ReactModule(name = HyperswitchNetcetera3dsModule.NAME)
class HyperswitchNetcetera3dsModule(reactContext: ReactApplicationContext) :
  NativeHyperswitchNetceteraSpec(reactContext) {
  val hsNetceteraUtils = HsNetceteraUtils()
  val applicationContext = reactApplicationContext.applicationContext as Application
  private fun getActivity(): Activity? {
    return currentActivity ?: reactApplicationContext.currentActivity
  }
  override fun getName(): String {
    return "HyperswitchNetcetera3ds"
  }

  @ReactMethod
  override fun initialiseNetceteraSDK(
    apiKey: String, hsSDKEnvironment: String, callback: Callback
  ) {
    try {
      HsNetceteraConfigurator.setConfigParameters(
        applicationContext,
        hsNetceteraUtils.hsSdkEnvironmetMapper(hsSDKEnvironment),
        apiKey
      )
      hsNetceteraUtils.intialiseNetceteraSDK(applicationContext, callback)
    } catch (err: Exception) {
      val map = Arguments.createMap()
      map.putString("status", "failure")
      map.putString("message", "netcetera sdk initialization fail" + err.message)
      callback.invoke(map)
    }
  }

  //5267648608924299

  @ReactMethod
  override fun generateAReqParams(
    messageVersion: String, directoryServerId: String, callback: Callback
  ) {
    hsNetceteraUtils.generateAReqParams(getActivity(), messageVersion, directoryServerId, callback)
  }

  @ReactMethod
  override fun recieveChallengeParamsFromRN(
    acsSignedContent: String,
    acsRefNumber: String,
    acsTransactionId: String,
    threeDSServerTransId: String,
    callback: Callback,
    threeDSRequestorAppURL: String?
  ) {
    val challengeParameters = HsNetceteraConfigurator.getChallengeParams(
      acsRefNumber,
      acsSignedContent,
      acsTransactionId,
      threeDSRequestorAppURL,
      threeDSServerTransId,
    )
    hsNetceteraUtils.setChallengeParameter(challengeParameters, callback)
  }

  @ReactMethod
  override fun generateChallenge(callback: Callback) {
    Log.i("Manideep", "reached here 3")
    hsNetceteraUtils.generateChallenge(getActivity(), 5, callback)
  }
  companion object{
    const val NAME = "HyperswitchNetcetera3ds"
  }
}
