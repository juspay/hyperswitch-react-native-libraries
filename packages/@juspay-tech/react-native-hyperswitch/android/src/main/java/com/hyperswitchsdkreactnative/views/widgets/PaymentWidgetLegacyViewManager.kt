package com.hyperswitchsdkreactnative.views.widgets

import android.app.Application
import android.content.Context
import android.graphics.Color
import android.graphics.drawable.Drawable
import android.util.Log
import android.view.Choreographer
import android.view.View
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.widget.FrameLayout
import androidx.fragment.app.FragmentActivity
import androidx.fragment.app.FragmentManager
import androidx.fragment.app.FragmentTransaction
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.annotations.ReactPropGroup
import com.hyperswitchsdkreactnative.BuildConfig
import com.hyperswitchsdkreactnative.provider.HyperProvider
import com.hyperswitchsdkreactnative.react.HyperFragment
import com.hyperswitchsdkreactnative.react.LaunchOptions
import com.hyperswitchsdkreactnative.react.ReactNativeController
import java.util.UUID
import kotlin.text.isEmpty

class PaymentWidgetLegacyViewManager : SimpleViewManager<PaymentWidgetView>() {
  override fun getName(): String = NAME
  private lateinit var launchOptions: LaunchOptions
  private var fragment: HyperFragment? = null
  private var context: ReactApplicationContext? = null

  override fun createViewInstance(reactContext: ThemedReactContext): PaymentWidgetView {
    launchOptions = LaunchOptions(reactContext.applicationContext, BuildConfig.VERSION_NAME)
    context = reactContext.reactApplicationContext
    ReactNativeController.initialize(reactContext.applicationContext as Application)
    return PaymentWidgetView(reactContext)
  }

  override fun onAfterUpdateTransaction(view: PaymentWidgetView) {
    super.onAfterUpdateTransaction(view)
    view.initWidget(HyperProvider.publishableKey())
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

  @ReactProp(name = "clientSecret")
  fun clientSecret(view: PaymentWidgetView, clientSecret: String?) {
    if (!clientSecret.isNullOrEmpty()) {
      view.setPaymentIntent(clientSecret)
      showWidgetInternal(view, view.id)
    }
  }

  @ReactProp(name = "options")
  fun options(view: PaymentWidgetView, options: String?) {
    options?.let {
      view.configuration(options)
    }
  }

  override fun getCommandsMap() = mapOf("createView" to COMMAND_CREATE)


  override fun receiveCommand(
    root: PaymentWidgetView, commandId: Int, args: ReadableArray?
  ) {
    super.receiveCommand(root, commandId, args)
    val reactNativeViewId = requireNotNull(args).getInt(0)
    when (commandId) {
      COMMAND_CREATE -> {
        showWidgetInternal(root, reactNativeViewId)
      }
    }
  }

  private fun showWidgetInternal(view: PaymentWidgetView, viewId: Int) {
      val activity = context?.currentActivity as FragmentActivity
      ?: throw IllegalStateException("PaymentWidget must be attached to a FragmentActivity")
    if (view.getClientSecret().isEmpty()) {
      view.post {
        showWidgetInternal(view, viewId)
      }
      return
    }
    try {
      if (fragment != null) {
        return
      }
      fragment = null
    } catch (_: Exception) {
      fragment = null
    }


    ReactNativeController.initialize(activity.application)

    fragment = HyperFragment.Builder().setComponentName("hyperSwitch").setLaunchOptions(
      launchOptions.getBundle(
        paymentIntentClientSecret = view.getClientSecret(),
        configuration = view.getConfiguration(),
        type = "widgetPaymentSheet"
      )
    ).build()

    val frameLayout = FrameLayout(activity)
    frameLayout.layoutParams = FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT)
    frameLayout.id = View.generateViewId()
    view.addView(
      frameLayout, FrameLayout.LayoutParams(
        MATCH_PARENT, MATCH_PARENT
      )
    )
    frameLayout.measure(
      View.MeasureSpec.makeMeasureSpec(view.width, View.MeasureSpec.EXACTLY),
      View.MeasureSpec.makeMeasureSpec(view.height, View.MeasureSpec.EXACTLY)
    )
    frameLayout.layout(0, 0, frameLayout.measuredWidth, frameLayout.measuredHeight)
    setupLayout(frameLayout)
    val fragmentManager: FragmentManager = activity.supportFragmentManager
    val fragmentTransaction: FragmentTransaction = fragmentManager.beginTransaction()
    fragmentTransaction.add(frameLayout.id, fragment!!, "HyperPaymentSheet")
    fragmentTransaction.addToBackStack("HyperPaymentSheet")
    fragmentTransaction.commitAllowingStateLoss()
    frameLayout.post {
      fragment?.view?.requestLayout()
    }
    Log.i("PaymentWidget", "Fragment transaction committed")
  }

  fun setupLayout(view: View) {
    Choreographer.getInstance().postFrameCallback(object: Choreographer.FrameCallback {
      override fun doFrame(frameTimeNanos: Long) {
        manuallyLayoutChildren(view)
        view.viewTreeObserver.dispatchOnGlobalLayout()
        Choreographer.getInstance().postFrameCallback(this)
      }
    })
  }

  private fun manuallyLayoutChildren(view: View) {
    val width = requireNotNull(view.width)
    val height = requireNotNull(view.height)

    view.measure(
      View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
      View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY))

    view.layout(0, 0, width, height)
  }


  companion object {
    const val NAME = "NativePaymentWidget"
    private const val COMMAND_CREATE = 1
  }
}
