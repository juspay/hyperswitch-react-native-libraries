package com.hyperswitchsdkreactnative.views

import android.util.Log
import androidx.fragment.app.FragmentActivity
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Dynamic
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.events.RCTEventEmitter
import com.facebook.react.viewmanagers.NativePaymentWidgetManagerDelegate
import com.facebook.react.viewmanagers.NativePaymentWidgetManagerInterface
import com.hyperswitchsdkreactnative.BuildConfig
import com.hyperswitchsdkreactnative.headless.HeadlessFlowController
import com.hyperswitchsdkreactnative.modules.HyperswitchRNWrapperNativeModule
import com.hyperswitchsdkreactnative.provider.LaunchOptions
import com.hyperswitchsdkreactnative.utils.HyperFragmentManager
import java.util.UUID

class PaymentWidgetViewManager : SimpleViewManager<PaymentWidgetView>(),
  NativePaymentWidgetManagerInterface<PaymentWidgetView> {

  private val mDelegate: ViewManagerDelegate<PaymentWidgetView> =
    NativePaymentWidgetManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<PaymentWidgetView> {
    return mDelegate
  }

  override fun getExportedCustomDirectEventTypeConstants() = mapOf(
    "onPaymentResult" to mapOf(
      "registrationName" to "onPaymentResult"
    ),
    "onPaymentEvent" to mapOf("registrationName" to "onPaymentEvent"),
  )

  // Track which views are CVC widgets for isCvcWidgetActive cleanup
  private val cvcWidgetViewIds = mutableSetOf<Int>()


  override fun getName(): String = NAME
  private lateinit var launchOptions: LaunchOptions
  private var context: ReactApplicationContext? = null
  private lateinit var view: PaymentWidgetView


  override fun createViewInstance(reactContext: ThemedReactContext): PaymentWidgetView {
    launchOptions = LaunchOptions(reactContext.applicationContext, BuildConfig.VERSION_NAME)
    context = reactContext.reactApplicationContext
    view = PaymentWidgetView(reactContext)
    return view
  }

  override fun onAfterUpdateTransaction(view: PaymentWidgetView) {
    super.onAfterUpdateTransaction(view)

    view.onPaymentResult { result ->
      val parsed = result[0] as? ReadableMap
      val jsonString = org.json.JSONObject().apply {
        put("status",  parsed?.getString("status")  ?: "")
        put("message", parsed?.getString("message") ?: "")
        parsed?.getString("error")?.let { put("error", it) }
        parsed?.getString("type")?.let  { put("type",  it) }
      }.toString()

      val event = Arguments.createMap().apply {
        putString("result", jsonString)
      }
      try {
        val reactContext = view.context as? ReactContext
        reactContext?.getJSModule(RCTEventEmitter::class.java)?.receiveEvent(
          view.id, "onPaymentResult", event
        )
      } catch (e: Exception) {
        Log.e("PaymentWidgetManager", "Failed to send payment result event", e)
      } finally {
        view.removeWidget()
      }
    }
    view.onEvent({ result ->
      val event: WritableMap = Arguments.createMap()
      event.putString("eventName", result.eventName)
      event.putMap("payload", result.payload)
      context?.getJSModule(RCTEventEmitter::class.java)?.receiveEvent(
        view.id,
        "onPaymentEvent",
        event
      )
    })
  }

  @ReactProp(name = "widgetId")
  override fun setWidgetId(view: PaymentWidgetView, widgetId: String?) {
    view.setWidgetId(
      widgetId ?: view.getWidgetId()
    )
  }

  @ReactProp(name = "widgetType")
  override fun setWidgetType(view: PaymentWidgetView, widgetType: String?) {
    view.setWidgetType(widgetType)
    if (widgetType == "cvcWidget") {
      cvcWidgetViewIds.add(view.id)
      HyperswitchRNWrapperNativeModule.isCvcWidgetActive = true
    }
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

    // If fragment already exists, tear it down and re-show
//    val tag = "HyperPaymentSheet_${view.id}"
//    val activity = context?.currentActivity as? FragmentActivity ?: return
//    val existingFragment = activity.supportFragmentManager.findFragmentByTag(tag)
//    if (existingFragment != null) {
//     view.removeWidget()
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


  override fun onDropViewInstance(view: PaymentWidgetView) {
    val tag = "HyperPaymentSheet_${view.id}"
    super.onDropViewInstance(view)
    view.cancelPendingInputEvents()
    view.stopLayout()
    val activity = context?.currentActivity as? FragmentActivity
    activity?.let { HyperFragmentManager.remove(it, tag) }
    // Clear CVC widget active flag when the last CVC widget view is dropped
    if (cvcWidgetViewIds.remove(view.id) && cvcWidgetViewIds.isEmpty()) {
      HyperswitchRNWrapperNativeModule.isCvcWidgetActive = false
      HeadlessFlowController.reset()
    }
  }

  companion object {
    const val NAME = "NativePaymentWidget"
    private const val SHOW_WIDGET = 0
    private const val REMOVE_WIDGET = 1
    private const val DEFAULT = -1
  }
}
