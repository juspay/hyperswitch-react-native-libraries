package com.hyperswitchsdkreactnative.views

import android.util.Log
import android.view.Choreographer
import android.view.View
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.widget.FrameLayout
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Dynamic
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.events.RCTEventEmitter
import com.facebook.react.viewmanagers.NativePaymentWidgetManagerDelegate
import com.facebook.react.viewmanagers.NativePaymentWidgetManagerInterface
import com.hyperswitchsdkreactnative.BuildConfig
import com.hyperswitchsdkreactnative.provider.HyperProvider
import com.hyperswitchsdkreactnative.provider.HyperFragment
import com.hyperswitchsdkreactnative.provider.LaunchOptions
import com.hyperswitchsdkreactnative.utils.HyperFragmentManager
import java.util.UUID

class PaymentWidgetViewManager : SimpleViewManager<PaymentWidgetView>(),
  NativePaymentWidgetManagerInterface<PaymentWidgetView>{

  private val mDelegate: ViewManagerDelegate<PaymentWidgetView> =
    NativePaymentWidgetManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<PaymentWidgetView> {
    return mDelegate
  }

  override fun getName(): String = NAME
  private lateinit var launchOptions: LaunchOptions
  private var context: ReactApplicationContext? = null
  private lateinit var view : PaymentWidgetView

  // Track choreographer callbacks per view to allow cleanup

  override fun createViewInstance(reactContext: ThemedReactContext): PaymentWidgetView {
    launchOptions = LaunchOptions(reactContext.applicationContext, BuildConfig.VERSION_NAME)
    context = reactContext.reactApplicationContext
    view =  PaymentWidgetView(reactContext)
    return view
  }

  override fun onAfterUpdateTransaction(view: PaymentWidgetView) {
    super.onAfterUpdateTransaction(view)
    val tag = "HyperPaymentSheet_${view.id}"
    val activity = context?.currentActivity as? FragmentActivity ?: return
    val existingFragment = activity.supportFragmentManager.findFragmentByTag(tag)
    if (existingFragment != null) {
      view.removeWidget()
      view.post { view.showWidgetInternal() }
    }
    view.onPaymentResult { result ->
      val event = Arguments.createMap().apply {
        putString("result", result[0] as String?)
      }

      try {
        val reactContext = view.context as? ReactContext
        reactContext?.getJSModule(RCTEventEmitter::class.java)?.receiveEvent(
          view.id, "topPaymentResult", event
        )
      } catch (e: Exception) {
        Log.e("PaymentWidgetManager", "Failed to send payment result event", e)
      } finally {
        view.removeWidget()
      }
    }
  }

  @ReactProp(name = "widgetId")
  override fun setWidgetId(view: PaymentWidgetView, widgetId: String?) {
    view.setWidgetId(
      widgetId ?: UUID.randomUUID().toString()
    )
  }

  @ReactProp(name = "widgetType")
  override fun setWidgetType(view: PaymentWidgetView, widgetType: String?) {
    view.setWidgetType(widgetType)
  }

  @ReactProp(name = "clientSecret")
  override fun setClientSecret(view: PaymentWidgetView, clientSecret: String?) {
    clientSecret ?: return
    if (view.getClientSecret() == clientSecret) return
    view.setPaymentIntent(clientSecret)
    view.post { view.showWidgetInternal() }
  }

  @ReactProp(name = "options")
  override fun setOptions(view: PaymentWidgetView, options: Dynamic?) {
    options ?: return
    val map = options.asMap()
    view.configuration(map)

//     If fragment already exists, tear it down and re-show
//    val tag = "HyperPaymentSheet_${view.id}"
//    val activity = context?.currentActivity as? FragmentActivity ?: return
//    val existingFragment = activity.supportFragmentManager.findFragmentByTag(tag)
//    if (existingFragment != null) {
//      removeWidget(view)
//      view.post { showWidgetInternal(view) }
//    }
  }

  override fun getCommandsMap() = mapOf(
    "showWidget" to SHOW_WIDGET,
    "removeWidget" to REMOVE_WIDGET,
    "default" to DEFAULT
  )

  @Deprecated("Deprecated in Java")
  override fun receiveCommand(root: PaymentWidgetView, commandId: Int, args: ReadableArray?) {
    super.receiveCommand(root, commandId, args)
    when (commandId) {
      SHOW_WIDGET -> view.showWidgetInternal()
      REMOVE_WIDGET -> view.removeWidget()
      DEFAULT -> Unit
    }
  }

  override fun getExportedCustomDirectEventTypeConstants() = mapOf(
    "topPaymentResult" to mapOf(
      "registrationName" to "onPaymentResult"
    )
  )


  override fun onDropViewInstance(view: PaymentWidgetView) {
    super.onDropViewInstance(view)
    view.cancelPendingInputEvents()
    view.stopLayout()
    val activity = context?.currentActivity as? FragmentActivity
    val tag = "HyperPaymentSheet_${view.id}"
    activity?.let { HyperFragmentManager.remove(it, tag) }
  }

  companion object {
    const val NAME = "NativePaymentWidget"
    private const val SHOW_WIDGET = 0
    private const val REMOVE_WIDGET = 1
    private const val DEFAULT = -1
  }
}
