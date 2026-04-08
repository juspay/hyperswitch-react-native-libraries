package com.hyperswitchsdkreactnative.provider

import android.app.Activity
import android.os.Bundle
import android.util.Log
import androidx.fragment.app.FragmentActivity
import androidx.fragment.app.FragmentManager
import androidx.fragment.app.FragmentTransaction
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableArray
import com.hyperswitchsdkreactnative.BuildConfig
internal class HyperProvider internal constructor(private val activity: Activity) {

  private var sdkAuthorization: String? = null

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

  fun initPaymentSession(sdkAuthorization: String) {
    this.sdkAuthorization = sdkAuthorization
  }

  fun presentPaymentSheet(readableMap: ReadableMap) {
    ReactNativeController.initialize(activity.application)
    val activity = activity as? FragmentActivity
    removeSheetView(true)
    activity?.let {
      val launchOptions = LaunchOptions(activity, BuildConfig.VERSION_NAME)
      reactFragment =
        HyperFragment.Builder()
          .setComponentName("hyperSwitch")
          .setLaunchOptions(launchOptions.getBundle(
            publishableKey = publishableKey,
            configuration = readableMap,
            customBackendUrl = customBackendUrl,
            customLogUrl = customLogUrl,
            customParams = customParams,
            sdkAuthorization = sdkAuthorization,
          ))
          .setFabricEnabled(BuildConfig.IS_NEW_ARCHITECTURE_ENABLED)
          .build()

      val fragmentManager: FragmentManager = it.supportFragmentManager
      val fragmentTransaction: FragmentTransaction = fragmentManager.beginTransaction()
      fragmentTransaction.add(android.R.id.content, reactFragment!!, "HyperPaymentSheet")
      fragmentTransaction.addToBackStack("HyperPaymentSheet")
      fragmentTransaction.commit()
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

    fun readableArrayToArrayList(readableArray: ReadableArray?): ArrayList<String> {
      val list = ArrayList<String>()
      if (readableArray == null) return list
      for (i in 0 until readableArray.size()) {
        list.add(readableArray.getString(i) ?: "")
      }
      return list
    }
  }
}
