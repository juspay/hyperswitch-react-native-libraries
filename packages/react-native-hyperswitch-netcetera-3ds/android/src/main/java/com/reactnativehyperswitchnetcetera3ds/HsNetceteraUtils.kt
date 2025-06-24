package com.reactnativehyperswitchnetcetera3ds

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.util.Log
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Callback
import com.netcetera.threeds.sdk.ThreeDS2ServiceInstance
import com.netcetera.threeds.sdk.api.ThreeDS2Service
import com.netcetera.threeds.sdk.api.transaction.Transaction
import com.netcetera.threeds.sdk.api.transaction.challenge.ChallengeParameters
import com.netcetera.threeds.sdk.api.transaction.challenge.ChallengeStatusReceiver
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.properties.Delegates


class HsNetceteraUtils {
  val threeDS2Service: ThreeDS2Service
  private lateinit var challengeParameters: ChallengeParameters
  private lateinit var transaction: Transaction

  constructor() {
    this.threeDS2Service = ThreeDS2ServiceInstance.get()
  }

  fun hsSdkEnvironmetMapper(environment: String): HsSDKEnviroment {
    return when (environment) {
      "PROD" -> HsSDKEnviroment.PROD
      "SANDBOX" -> HsSDKEnviroment.SANDBOX
      "INTEG" -> HsSDKEnviroment.INTEG
      else -> HsSDKEnviroment.SANDBOX
    }
  }

  fun setChallengeParameter(challengeParameters: ChallengeParameters, callback: Callback) {
    this.challengeParameters = challengeParameters
    val map = Arguments.createMap();
    if (challengeParameters != null) {
      map.putString("status", "success")
      map.putString("message", "challenge params receive successful")
      callback.invoke(map)

    } else {
      map.putString("status", "failure")
      map.putString("message", "challenge params receive failure")
      callback.invoke(map)
    }

  }

  fun intialiseNetceteraSDK(context: Context, callback: Callback) {
//    Log.i("initialise Netcetera", "ok")
//    Log.i("initialise Netcetera", threeDS2Service.toString())
    val map = Arguments.createMap()
    CoroutineScope(Dispatchers.IO).launch {
      threeDS2Service.initialize(context, HsNetceteraConfigurator.configParams, "en", null, object :
        ThreeDS2Service.InitializationCallback {
        override fun onCompleted() {
          //...

//          Log.i("Initialization Success", "ok")
          map.putString("status", "success")
          map.putString("message", "netcetera sdk initialization successful")
          callback.invoke(map)
        }

        override fun onError(throwable: Throwable) {


          if (ThreeDS2ServiceInstance.get() !== null && throwable.message?.contains("ThreeDS2Service is already initialized Error code: [1021]") == true) {
//            Log.i("flow working", "ok")
            map.putString("status", "success")
            map.putString("message", "netcetera sdk initialization successful")
            callback.invoke(map)
          } else {
//            Log.i("Initialization Fail", throwable.message.toString())
            map.putString("status", "failure")
            map.putString(
              "message",
              "netcetera sdk initialization failed " + throwable.message.toString()
            )
            callback.invoke(map)
          }
        }
      })
    }


  }

  fun generateAReqParams(activity: Activity?, messageVersion: String, directoryServerId: String, callback: Callback) {

    val statusMap = Arguments.createMap()
    try {
      transaction = threeDS2Service.createTransaction(
        directoryServerId,
        messageVersion
      )
      activity?.runOnUiThread {
        transaction.getProgressView(activity)
      }
      val aReqMap = Arguments.createMap()
      aReqMap.putString("deviceData", transaction.authenticationRequestParameters.deviceData)
      aReqMap.putString(
        "messageVersion",
        transaction.authenticationRequestParameters.messageVersion
      )
      aReqMap.putString("sdkTransId", transaction.authenticationRequestParameters.sdkTransactionID)
      aReqMap.putString("sdkAppId", transaction.authenticationRequestParameters.sdkAppID)
      aReqMap.putString(
        "sdkEphemeralKey",
        transaction.authenticationRequestParameters.sdkEphemeralPublicKey
      )
      aReqMap.putString(
        "sdkReferenceNo",
        transaction.authenticationRequestParameters.sdkReferenceNumber
      )
      statusMap.putString("status", "success")
      statusMap.putString("message", "AReq Params generation successful")
      callback.invoke(statusMap, aReqMap)


    } catch (err: Exception) {
      statusMap.putString("status", "error")
      statusMap.putString("message", "AReq Params generation failure " + err.message)
      callback.invoke(statusMap)
    }


  }

  fun generateChallenge(activity: Activity?, timeOut: Int, callback: Callback) {
    val challengeStatusReceiver: HsChallengeManager = HsChallengeManager()
    challengeStatusReceiver.setPostHsChallengeCallback(callback)
//    Log.i("Challenge", challengeParameters.acsSignedContent)

    CoroutineScope(Dispatchers.IO).launch {
      withContext(Dispatchers.Main) {
        try {
          if(activity!=null) {
            transaction.doChallenge(
              activity,
              challengeParameters,
              challengeStatusReceiver,
              timeOut
            )
          } else {
            val statusMap = Arguments.createMap()
            statusMap.putString("status", "error")
            statusMap.putString("message", "Activity instance not found")
            callback.invoke(statusMap)
          }

//          Log.i("Challenge", "success")
        } catch (err: Exception) {
//          Log.i("Challenge", err.message.toString())
        }
      }
    }
  }


}
