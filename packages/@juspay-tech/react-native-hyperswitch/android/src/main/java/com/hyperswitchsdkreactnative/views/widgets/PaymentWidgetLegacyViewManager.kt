package com.hyperswitchsdkreactnative.views.widgets

import android.app.Application
import android.content.Context
import android.graphics.Color
import android.graphics.drawable.Drawable
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import androidx.fragment.app.FragmentActivity
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.annotations.ReactPropGroup
import com.hyperswitchsdkreactnative.BuildConfig
import com.hyperswitchsdkreactnative.provider.HyperProvider
import com.hyperswitchsdkreactnative.provider.HyperProvider.Companion.reactFragment
import com.hyperswitchsdkreactnative.react.HyperFragment
import com.hyperswitchsdkreactnative.react.LaunchOptions
import com.hyperswitchsdkreactnative.react.ReactNativeController
import com.hyperswitchsdkreactnative.views.googlepay.GooglePayButtonView
import java.util.UUID
import kotlin.text.isEmpty

class PaymentWidgetLegacyViewManager : SimpleViewManager<PaymentWidgetView>() {
  override fun getName(): String = NAME
  private lateinit var launchOptions : LaunchOptions

  private var fragment : HyperFragment? = null
  private var context : ReactApplicationContext? = null

  override fun createViewInstance(reactContext: ThemedReactContext): PaymentWidgetView {
    Log.i("Manideep", "View Created ${reactContext.toString()}")
    launchOptions = LaunchOptions(reactContext.applicationContext, BuildConfig.VERSION_NAME)
    context = reactContext.reactApplicationContext
    ReactNativeController.initialize(reactContext.applicationContext as Application)
    return PaymentWidgetView(reactContext)
  }

  override fun onAfterUpdateTransaction(view: PaymentWidgetView) {
    super.onAfterUpdateTransaction(view)
    Log.i("Manideep", "${view.id}")
    view.initWidget(HyperProvider.publishableKey())
  }

  override fun onLayoutChange(
    v: View?,
    left: Int,
    top: Int,
    right: Int,
    bottom: Int,
    oldLeft: Int,
    oldTop: Int,
    oldRight: Int,
    oldBottom: Int
  ) {
    super.onLayoutChange(v, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom)
  }


  @ReactProp(name = "widgetId")
  fun widgetId(view: PaymentWidgetView, widgetId: String?) {
    val id = if (widgetId.isNullOrBlank()) {
      UUID.randomUUID().toString()
    } else {
      widgetId
    }
    view.setSessionId(id)
  }

  @ReactProp(name = "widgetType")
  fun widgetType(view: PaymentWidgetView, widgetType: String?) {
    view.setWidgetType(WidgetType.from(widgetType))
  }

//  @ReactPropGroup(names = ["width", "height"])
//  fun width(view: PaymentWidgetView, width: Int, height: Int) {
//    Log.i("Manideep", "Width : ${width} Height : ${height}")
//    view.layoutParams = FrameLayout.LayoutParams(width, height)
//  }

  @ReactProp(name = "clientSecret")
  fun clientSecret(view: PaymentWidgetView, clientSecret: String?) {
    if (!clientSecret.isNullOrEmpty()) {
      view.setPaymentIntent(clientSecret)
      showWidgetInternal(view)
    }
  }

  @ReactProp(name = "options")
  fun options(view: PaymentWidgetView, options: String?) {
    options?.let {
      view.configuration(options)
    }
  }

  private fun showWidgetInternal(view: PaymentWidgetView) {
    val activity = context?.currentActivity as FragmentActivity
      ?: throw IllegalStateException("PaymentWidget must be attached to a FragmentActivity")
    try {
      if (fragment != null) {
        fragment!!.unRegisterEventBus()
        activity.supportFragmentManager.beginTransaction().remove(fragment!!)
          .commitNowAllowingStateLoss()
      }
      fragment = null
      if (view.id == View.NO_ID) {
        Log.i("Manideep", "No ID, Creating New")
        view.id = View.generateViewId()
      }
    } catch (_: Exception) {
    }
    fragment = HyperFragment.Builder()
      .setComponentName("hyperSwitch")
      .setLaunchOptions(
        launchOptions.getBundle(
          paymentIntentClientSecret = view.getClientSecret(),
          configuration = view.getConfiguration(),
          type = "widgetPaymentSheet"
        )
      )
      .build()
    if (!view.isAttachedToWindow) {
      return
    }
    Log.i("Manideep","layout params $view.layoutParams")

    fragment?.let {
      activity.supportFragmentManager.beginTransaction()
        .replace(view.id, it)
        .commitAllowingStateLoss()
    }
  }


  companion object {
    const val NAME = "NativePaymentWidget"
  }
}
