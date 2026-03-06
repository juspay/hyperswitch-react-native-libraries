package com.hyperswitchsdkreactnative.provider

import android.app.Activity
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.view.View
import android.webkit.WebSettings
import android.view.WindowInsets
import androidx.annotation.RequiresApi
import androidx.fragment.app.FragmentActivity
import androidx.fragment.app.FragmentManager
import androidx.fragment.app.FragmentTransaction
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableType
import com.facebook.react.bridge.ReadableArray
import com.hyperswitchsdkreactnative.BuildConfig
import org.json.JSONObject
import org.json.JSONArray

internal class HyperProvider internal constructor(private val activity: Activity) {

  private var clientSecret: String? = null

  fun initialise(
    publishableKey: String?,
    customBackendUrl: String?,
    customLogUrl: String?,
    customParams: ReadableMap?
  ) {
    Companion.publishableKey = publishableKey
    Companion.customBackendUrl = customBackendUrl
    Companion.customLogUrl = customLogUrl
    Companion.customParams = customParams
  }

  fun initPaymentSession(clientSecret: String) {
    this.clientSecret = clientSecret
  }

  fun presentPaymentSheet(readableMap: ReadableMap) {
    ReactNativeController.initialize(activity.application)
    val activity = activity as? FragmentActivity
    removeSheetView(true) // remove any existing payment sheet
    activity?.let {
      val launchOptions = LaunchOptions(activity, BuildConfig.VERSION_NAME)
      reactFragment =
        HyperFragment.Builder()
          .setComponentName("hyperSwitch")
          .setLaunchOptions(launchOptions.getBundle(publishableKey, clientSecret, readableMap, customBackendUrl, customLogUrl, customParams))
          .setFabricEnabled(BuildConfig.IS_NEW_ARCHITECTURE_ENABLED)
          .build()

      val fragmentManager: FragmentManager = it.supportFragmentManager
      val fragmentTransaction: FragmentTransaction = fragmentManager.beginTransaction()
      fragmentTransaction.add(android.R.id.content, reactFragment!!, "HyperPaymentSheet")
      fragmentTransaction.addToBackStack("HyperPaymentSheet")
      fragmentTransaction.commit()
    } ?: run {
//      callback(PaymentResult(status = "failed", message = "Activity is not a FragmentActivity"))
    }
  }

  fun removeSheetView(reset: Boolean) {
    val activity = activity as? FragmentActivity
    activity?.let {
      try {
        if (reactFragment != null) {
          reactFragment!!.unRegisterEventBus()
          it.supportFragmentManager.beginTransaction().remove(reactFragment!!).commitAllowingStateLoss()
        }
        if (reset) {
          reactFragment = null
        }
      } catch (_: Exception) {
      }
    }
  }

  companion object {
    @JvmStatic
    var reactFragment: HyperFragment? = null
    @JvmStatic
    var publishableKey: String? = null
    @JvmStatic
    var customBackendUrl: String? = null
    @JvmStatic
    var customLogUrl: String? = null
    @JvmStatic
    var customParams: ReadableMap? = null
  }
}
