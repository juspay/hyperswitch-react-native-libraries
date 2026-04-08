package com.hyperswitchsdkreactnative.provider

import android.annotation.SuppressLint
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import com.facebook.react.ReactFragment
import com.facebook.react.ReactHost
import com.facebook.react.ReactInstanceEventListener
import com.facebook.react.ReactNativeHost
import com.facebook.react.ReactRootView
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.facebook.react.views.scroll.ReactHorizontalScrollView
import com.facebook.react.views.scroll.ReactScrollView
import com.hyperswitchsdkreactnative.headless.ExitHeadlessCallBackManager
import com.hyperswitchsdkreactnative.headless.PaymentResult
import com.hyperswitchsdkreactnative.modules.EventName
import com.proyecto26.inappbrowser.ChromeTabsDismissedEvent
import com.proyecto26.inappbrowser.ChromeTabsManagerActivity
import io.hyperswitch.redirect.RedirectEvent
import org.greenrobot.eventbus.EventBus
import org.greenrobot.eventbus.Subscribe
import java.util.concurrent.ConcurrentHashMap

data class OnEventResult(
  val eventName: String,
  val payload: ReadableMap? = null
)

typealias EventCallback = (OnEventResult) -> Unit

class HyperFragment : ReactFragment() {
  private lateinit var onPaymentResult: Callback

  private lateinit var eventResultCallback: EventCallback
  fun setOnPaymentResult(callback: Callback) {
    this.onPaymentResult = callback
    paymentEventCallbacks[view?.id ?: -1] = onPaymentResult
  }

  fun setOnEventCallback(eventCallback: EventCallback) {
    this.eventResultCallback = eventCallback
    onEventCallBacks[this.getWidgetIdFromLaunchOptions()] = eventCallback
  }

  private fun getWidgetIdFromLaunchOptions(): String{
    val launchOptions = arguments?.getBundle("arg_launch_options")
    return try {
      launchOptions?.getBundle("props")?.getString("widgetId")
    } catch (e: Exception) {
      "-1"
    }.toString()
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    registerEventBus()
    reactDelegate.reactInstanceManager?.addReactInstanceEventListener(listener)
  }

  private val listener = object : ReactInstanceEventListener {
    override fun onReactContextInitialized(reactContext: ReactContext) {
      val rootTag = reactDelegate.reactRootView?.rootViewTag ?: -1
      if (::onPaymentResult.isInitialized) {
        paymentEventCallbacks[rootTag] = onPaymentResult
      }

      if (::eventResultCallback.isInitialized) {
        onEventCallBacks[getWidgetIdFromLaunchOptions()] = eventResultCallback
      }
    }
  }

  override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
    super.onViewCreated(view, savedInstanceState)

    // ReactRootView is the root of this fragment
    val reactRootView = view as? ReactRootView ?: return

    // Wait for RN tree to mount, then fix scroll interception
    reactRootView.setOnHierarchyChangeListener(
      object : ViewGroup.OnHierarchyChangeListener {
        override fun onChildViewAdded(parent: View?, child: View?) {
          // Once RN tree is mounted, fix scroll interception for all ReactScrollViews
          view.post { fixScrollInterception(reactRootView) }
        }

        override fun onChildViewRemoved(parent: View?, child: View?) {}
      }
    )
  }

  fun confirmPayment(callback: Callback) {
    val rootTag = view?.id
    if(rootTag == -1){
      callback.invoke("ERROR","FAILED")
      return
    }

    if (confirmActionCallbacks.get(rootTag) != null) {
      callback.invoke("ERROR", "ALREADY_IN_PROGRESS")
      return
    }
    confirmActionCallbacks[rootTag as Int] = callback
    val map = Arguments.createMap()
    map.putString("actionType", EventName.CONFIRM_PAYMENT_ACTION.name)
    map.putInt("rootTag", rootTag)
    reactDelegate.currentReactContext
      ?.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
      ?.emit("triggerWidgetAction", map)
  }

  fun confirmCvcPayment(callback: Callback, paymentToken: String, paymentMethodId: String) {
    val rootTag = view?.id ?: -1
    if(rootTag == -1){
      callback.invoke("ERROR","FAILED")
      return
    }

    // Wire ExitHeadlessCallBackManager so that when CvcWidget JS calls exitHeadless(result),
    // the result flows back to our callback → promise.resolve in the wrapper module.
    ExitHeadlessCallBackManager.setCallback { result: PaymentResult ->
      val json = org.json.JSONObject()
      when (result) {
        is PaymentResult.Completed -> {
          json.put("status", "success")
          json.put("message", "Payment confirmed successfully")
          json.put("data", result.data)
        }
        is PaymentResult.Failed -> {
          json.put("status", "failed")
          json.put("code", result.throwable.cause?.message ?: "UNKNOWN_ERROR")
          json.put("message", result.throwable.message ?: "An error has occurred.")
        }
        is PaymentResult.Canceled -> {
          json.put("status", "cancelled")
          json.put("message", "Payment confirmation cancelled")
          json.put("data", result.data)
        }
      }
      callback.invoke(json.toString())
    }

    val map = Arguments.createMap()
    map.putString("actionType", EventName.CONFIRM_CVC_PAYMENT.name)
    map.putInt("rootTag", rootTag)
    map.putString("paymentToken", paymentToken)
    map.putString("paymentMethodId", paymentMethodId)
    reactDelegate.currentReactContext
      ?.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
      ?.emit("triggerWidgetAction", map)
  }


  /**
   * Fix scroll interception for ReactScrollViews inside this fragment.
   * This enables the inner RN ScrollView to properly receive and handle touch events
   * even when nested inside another RN ScrollView (in a separate React root).
   */
  @SuppressLint("ClickableViewAccessibility")
  private fun fixScrollInterception(root: ViewGroup) {
    // Enable nested scrolling on the root
    root.isNestedScrollingEnabled = true

    // Walk the tree and fix all ReactScrollViews
    findReactScrollViews(root).forEach { scrollView ->
      scrollView.isNestedScrollingEnabled = true
      scrollView.setOnTouchListener { v, event ->
        when (event.action) {
          MotionEvent.ACTION_DOWN,
          MotionEvent.ACTION_MOVE -> {
            // Tell parent to not intercept - we want to handle this scroll
            v.parent?.requestDisallowInterceptTouchEvent(true)
          }

          MotionEvent.ACTION_UP,
          MotionEvent.ACTION_CANCEL -> {
            // Release the intercept lock
            v.parent?.requestDisallowInterceptTouchEvent(false)
          }
        }
        // Return false to let the ScrollView's normal touch handling continue
        false
      }
    }
  }

  /**
   * Recursively find all ReactScrollViews and ReactHorizontalScrollViews in the view hierarchy.
   */
  private fun findReactScrollViews(root: ViewGroup): List<ViewGroup> {
    val result = mutableListOf<ViewGroup>()
    for (i in 0 until root.childCount) {
      val child = root.getChildAt(i)
      if (child is ReactScrollView || child is ReactHorizontalScrollView) {
        result.add(child as ViewGroup)
      }
      if (child is ViewGroup) {
        result.addAll(findReactScrollViews(child))
      }
    }
    return result
  }

  override fun onCreateView(
    inflater: LayoutInflater,
    container: ViewGroup?,
    savedInstanceState: Bundle?
  ): View? {
    val view = super.onCreateView(inflater, container, savedInstanceState)
    if (view is ReactRootView) {
      view.layoutParams = FrameLayout.LayoutParams(
        FrameLayout.LayoutParams.MATCH_PARENT,
        FrameLayout.LayoutParams.MATCH_PARENT
      )
    }
    return view
  }

  override fun getReactNativeHost(): ReactNativeHost {
    return ReactNativeController.getReactNativeHost()
  }

  override fun getReactHost(): ReactHost {
    return ReactNativeController.getReactHost()
  }

  override fun onDestroyView() {
    (view as? ReactRootView)?.unmountReactApplication()
    super.onDestroyView()
  }

  override fun onDestroy() {
    super.onDestroy()
    unRegisterEventBus()
  }

  private fun registerEventBus() {
    if (!EventBus.getDefault().isRegistered(this)) {
      EventBus.getDefault().register(this)
    }
  }

  fun unRegisterEventBus() {
    if (EventBus.getDefault().isRegistered(this)) {
      EventBus.getDefault().unregister(this)
    }
  }

  @Subscribe
  fun onEvent(event: RedirectEvent) {
    unRegisterEventBus()
    EventBus.getDefault().post(
      ChromeTabsDismissedEvent(
        event.message,
        event.resultType,
        event.isError
      )
    )
    startActivity(ChromeTabsManagerActivity.createDismissIntent(requireContext()))
  }

  companion object {
    @Volatile
    private var confirmActionCallbacks = ConcurrentHashMap<Int, Callback>()

    @Volatile
    private var paymentEventCallbacks = ConcurrentHashMap<Int, Callback>()

    @Volatile
    private var onEventCallBacks = ConcurrentHashMap<String, EventCallback>()
    fun onPaymentResultEvent(rootTag: Int, result: String) {
      try {
        confirmActionCallbacks[rootTag]?.invoke(result)
        paymentEventCallbacks[rootTag]?.invoke(result)
      } catch (e: Exception) {
        e.printStackTrace()
        Log.e("HyperModule", "Error in paymentResult")
      }
    }

    fun onEvents(widgetId: String, eventType: String, result: ReadableMap) {
      try {
        onEventCallBacks[widgetId]?.invoke(
          OnEventResult(
            eventType,
            result
          )
        )
      } catch (_: Exception) {
        Log.e("HyperModule", "Error in resolveConfirmPayment")
      }
    }

    fun resolveConfirmPayment(rootTag: Int, result: String) {
      try {
        confirmActionCallbacks[rootTag]?.invoke(result)
        confirmActionCallbacks.remove(rootTag)
      } catch (e: Exception) {
        e.printStackTrace()
        Log.e("HyperModule", "Error in resolveConfirmPayment")
      }
    }
  }

  class Builder {
    var mComponentName: String? = null
    var mLaunchOptions: Bundle? = null
    var mFabricEnabled: Boolean = false
    fun setComponentName(componentName: String?): Builder {
      mComponentName = componentName
      return this
    }

    fun setLaunchOptions(launchOptions: Bundle?): Builder {
      mLaunchOptions = launchOptions
      return this
    }

    fun build(): HyperFragment {
      val ARG_COMPONENT_NAME = "arg_component_name"
      val ARG_LAUNCH_OPTIONS = "arg_launch_options"
      val ARG_FABRIC_ENABLED = "arg_fabric_enabled"
      val fragment = HyperFragment()
      val args = Bundle()
      args.putString(ARG_COMPONENT_NAME, mComponentName)
      args.putBundle(ARG_LAUNCH_OPTIONS, mLaunchOptions)
      args.putBoolean(ARG_FABRIC_ENABLED, mFabricEnabled)
      fragment.setArguments(args)
      return fragment
    }

    fun setFabricEnabled(fabricEnabled: Boolean): Builder {
      mFabricEnabled = fabricEnabled
      return this
    }
  }
}
