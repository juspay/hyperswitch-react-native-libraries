package com.hyperswitchsdkreactnative.views.widgets

import android.util.Log
import android.view.Choreographer
import android.view.View
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.widget.FrameLayout
import androidx.fragment.app.FragmentActivity
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.WritableNativeMap
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.events.EventDispatcher
import com.facebook.react.fabric.FabricUIManager
import com.facebook.react.bridge.UIManager
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.common.UIManagerType
import com.hyperswitchsdkreactnative.BuildConfig
import com.hyperswitchsdkreactnative.PaymentSheetResult
import com.hyperswitchsdkreactnative.provider.HyperProvider
import com.hyperswitchsdkreactnative.react.HyperFragment
import com.hyperswitchsdkreactnative.react.LaunchOptions
import com.hyperswitchsdkreactnative.utils.HyperFragmentManager
import org.json.JSONObject
import java.util.UUID

class PaymentWidgetViewManager : SimpleViewManager<PaymentWidgetView>() {

  override fun getName(): String = NAME

  private lateinit var launchOptions: LaunchOptions
  private var context: ReactApplicationContext? = null

  // Track choreographer callbacks per view to allow cleanup
  private val choreographerCallbacks = mutableMapOf<Int, Choreographer.FrameCallback>()

  override fun createViewInstance(reactContext: ThemedReactContext): PaymentWidgetView {
    launchOptions = LaunchOptions(reactContext.applicationContext, BuildConfig.VERSION_NAME)
    context = reactContext.reactApplicationContext
    return PaymentWidgetView(reactContext)
  }

  override fun onAfterUpdateTransaction(view: PaymentWidgetView) {
    super.onAfterUpdateTransaction(view)
    view.onPaymentResult { result ->
      val status = when (result) {
        is PaymentSheetResult.Completed -> "completed"
        is PaymentSheetResult.Canceled -> "canceled"
        is PaymentSheetResult.Failed -> "failed"
      }

      val payload = WritableNativeMap().apply {
        putString("status", status)
        if (result is PaymentSheetResult.Failed) {
          putString("errorMessage", result.error?.message)
        }
      }

      try {
        dispatchEvent(view, "topPaymentResult", payload)
      } catch (e: Exception) {
        Log.e("PaymentWidgetManager", "Failed to send payment result event", e)
      } finally {
        removeWidget(view)
      }
    }
  }

  /**
   * Dispatches an event using Fabric (New Architecture) EventDispatcher.
   * Falls back gracefully if surface ID is unavailable.
   */
  private fun dispatchEvent(
    view: PaymentWidgetView,
    eventName: String,
    payload: WritableNativeMap
  ) {
    val reactContext = view.context as? ThemedReactContext ?: return
    val surfaceId = UIManagerHelper.getSurfaceId(view)
    val eventDispatcher = UIManagerHelper.getEventDispatcherForReactTag(reactContext, view.id)

    eventDispatcher?.dispatchEvent(
      PaymentResultEvent(
        surfaceId = surfaceId,
        viewTag = view.id,
        eventName = eventName,
        payload = payload
      )
    )
  }

  @ReactProp(name = "widgetId")
  fun setWidgetId(view: PaymentWidgetView, widgetId: String) {
    view.setWidgetId(widgetId.ifBlank { UUID.randomUUID().toString() })
  }

  @ReactProp(name = "widgetType")
  fun setWidgetType(view: PaymentWidgetView, widgetType: String?) {
    view.setWidgetType(WidgetType.from(widgetType))
  }

  @ReactProp(name = "options")
  fun setOptions(view: PaymentWidgetView, options: String?) {
    options ?: return
    view.configuration(options)
    val clientSecret = JSONObject(options).optString("clientSecret")
      .takeIf { it.isNotBlank() && it != "null" } ?: return
    view.setPaymentIntent(clientSecret)
  }

  override fun getCommandsMap() = mapOf(
    "showWidget" to SHOW_WIDGET,
    "removeWidget" to REMOVE_WIDGET,
    "default" to DEFAULT
  )

  override fun receiveCommand(root: PaymentWidgetView, commandId: String, args: com.facebook.react.bridge.ReadableArray?) {
    when (commandId) {
      "showWidget", SHOW_WIDGET.toString() -> showWidgetInternal(root)
      "removeWidget", REMOVE_WIDGET.toString() -> removeWidget(root)
    }
  }

  // Keep legacy Int overload for Paper compatibility during migration
  @Deprecated("Deprecated in Java")
  override fun receiveCommand(root: PaymentWidgetView, commandId: Int, args: com.facebook.react.bridge.ReadableArray?) {
    super.receiveCommand(root, commandId, args)
    when (commandId) {
      SHOW_WIDGET -> showWidgetInternal(root)
      REMOVE_WIDGET -> removeWidget(root)
    }
  }

  override fun getExportedCustomDirectEventTypeConstants() = mapOf(
    "topPaymentResult" to mapOf(
      "registrationName" to "onPaymentResult"
    )
  )

  private fun showWidgetInternal(view: PaymentWidgetView) {
    if (view.isClientSecretEmpty()) {
      view.post { showWidgetInternal(view) }
      return
    }
    view.initWidget(HyperProvider.publishableKey())

    val activity = context?.currentActivity as? FragmentActivity
      ?: throw IllegalStateException("PaymentWidget must be attached to a FragmentActivity")

    if (activity.isFinishing || activity.isDestroyed) return

    val tag = "HyperPaymentSheet_${view.id}"
    HyperFragmentManager.cancelPending(tag)

    val fragment = HyperFragment.Builder()
      .setComponentName("hyperSwitch")
      .setLaunchOptions(view.getLaunchOptions())
      .build()

    val frameLayout = FrameLayout(activity).apply {
      layoutParams = FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT)
    }

    view.addView(frameLayout, FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT))

    frameLayout.post {
      frameLayout.measure(
        View.MeasureSpec.makeMeasureSpec(view.width, View.MeasureSpec.EXACTLY),
        View.MeasureSpec.makeMeasureSpec(view.height, View.MeasureSpec.EXACTLY)
      )
      frameLayout.layout(0, 0, frameLayout.measuredWidth, frameLayout.measuredHeight)
      setupLayout(frameLayout)

      HyperFragmentManager.addOrReplace(
        activity = activity,
        container = frameLayout,
        fragment = fragment,
        tag = tag
      )

      frameLayout.post { fragment.view?.requestLayout() }
    }
  }

  private fun removeWidget(view: PaymentWidgetView) {
    try {
      val activity = context?.currentActivity as? FragmentActivity ?: return
      val tag = "HyperPaymentSheet_${view.id}"
      HyperFragmentManager.remove(activity, tag)
      stopLayout(view.id)
    } catch (_: Exception) {}
  }

  private fun setupLayout(view: View) {
    val callback = object : Choreographer.FrameCallback {
      override fun doFrame(frameTimeNanos: Long) {
        if (view.isAttachedToWindow) {
          manuallyLayoutChildren(view)
          view.viewTreeObserver.dispatchOnGlobalLayout()
          Choreographer.getInstance().postFrameCallback(this)
        } else {
          choreographerCallbacks.remove(view.id)
        }
      }
    }
    choreographerCallbacks[view.id] = callback
    Choreographer.getInstance().postFrameCallback(callback)
  }

  private fun stopLayout(viewId: Int) {
    choreographerCallbacks.remove(viewId)?.let {
      Choreographer.getInstance().removeFrameCallback(it)
    }
  }

  private fun manuallyLayoutChildren(view: View) {
    view.measure(
      View.MeasureSpec.makeMeasureSpec(view.width, View.MeasureSpec.EXACTLY),
      View.MeasureSpec.makeMeasureSpec(view.height, View.MeasureSpec.EXACTLY)
    )
    view.layout(0, 0, view.width, view.height)
  }

  override fun onDropViewInstance(view: PaymentWidgetView) {
    super.onDropViewInstance(view)
    val activity = context?.currentActivity as? FragmentActivity
    val tag = "HyperPaymentSheet_${view.id}"
    activity?.let { HyperFragmentManager.remove(it, tag) }
    stopLayout(view.id)
  }

  companion object {
    const val NAME = "NativePaymentWidget"
    private const val SHOW_WIDGET = 1
    private const val REMOVE_WIDGET = 2
    private const val DEFAULT = -1
  }
}
