package com.hyperswitchsdkreactnative.views

import android.app.Activity
import android.util.Log
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Dynamic
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.NativePaymentWidgetManagerDelegate
import com.facebook.react.viewmanagers.NativePaymentWidgetManagerInterface
import com.hyperswitchsdkreactnative.modules.HyperswitchRNWrapperNativeModule
import io.hyperswitch.model.HyperswitchConfiguration
import io.hyperswitch.model.PaymentSessionConfiguration
import com.facebook.react.uimanager.events.RCTEventEmitter
import io.hyperswitch.PaymentEvent
import io.hyperswitch.PaymentEventListener
import io.hyperswitch.sdk.Elements
import io.hyperswitch.sdk.Hyperswitch
import io.hyperswitch.sdk.HyperswitchBoundElement
import io.hyperswitch.sdk.HyperswitchInstance
import io.hyperswitch.view.HyperswitchElement
import java.util.WeakHashMap

class PaymentElementViewManager : SimpleViewManager<HyperswitchElement>(),
  NativePaymentWidgetManagerInterface<HyperswitchElement> {

  private val mDelegate: ViewManagerDelegate<HyperswitchElement> =
    NativePaymentWidgetManagerDelegate(this)
  private val viewStates = WeakHashMap<HyperswitchElement, WidgetState>()

  override fun getDelegate(): ViewManagerDelegate<HyperswitchElement> {
    return mDelegate
  }

  private var context: ReactApplicationContext? = null

  override fun getName(): String = NAME

  override fun createViewInstance(reactContext: ThemedReactContext): HyperswitchElement {
    context = reactContext.reactApplicationContext
    val container = NativeWidgetContainer(context?.currentActivity)
    viewStates[container] = WidgetState()
    return container
  }

  override fun onAfterUpdateTransaction(container: HyperswitchElement) {
    super.onAfterUpdateTransaction(container)
    initWidgetIfReady(container)
  }

  @ReactProp(name = "widgetType")
  override fun setWidgetType(container: HyperswitchElement, widgetType: String?) {
    stateFor(container).props.widgetType = widgetType
  }

  @ReactProp(name = "sdkAuthorization")
  override fun setSdkAuthorization(container: HyperswitchElement, sdkAuthorization: String?) {
    stateFor(container).props.sdkAuthorization = sdkAuthorization
  }

  @ReactProp(name = "options")
  override fun setOptions(container: HyperswitchElement, options: Dynamic?) {
    val props = stateFor(container).props
    if (options == null || options.isNull) {
      props.optionsSdkAuthorization = null
      props.publishableKey = null
      props.profileId = null
      props.optionsMap = null
      return
    }

    try {
      val map = options.asMap()
      props.optionsSdkAuthorization = map.getStringOrNull("sdkAuthorization")
      props.publishableKey = map.getStringOrNull("publishableKey")
      props.profileId = map.getStringOrNull("profileId")
      props.optionsMap = readableMapToMap(map)
    } catch (e: Exception) {
      Log.w(NAME, "Ignoring malformed widget options", e)
    }
  }

  override fun onDropViewInstance(container: HyperswitchElement) {
    viewStates[container]?.let { state ->
      clearWidget(state, removeWidget = true)
    }
    viewStates.remove(container)
    super.onDropViewInstance(container)
  }

  private fun initWidgetIfReady(container: HyperswitchElement) {
    val state = stateFor(container)
    val props = state.props

    if (!props.isSupportedWidgetType()) {
      if (state.hasWidget()) {
        clearWidget(state, removeWidget = true)
      }
      return
    }

    val publishableKey = props.effectivePublishableKey() ?: return
    val sdkAuthorization = props.effectiveSdkAuthorization() ?: return
    val profileId = props.effectiveProfileId()
    val configKey = listOf(publishableKey, profileId.orEmpty()).joinToString(":")

    val activity = context?.currentActivity ?: run {
      Log.w(NAME, "Cannot initialize Hyperswitch widget without current activity")
      return
    }

    container.type = props.widgetType
    state.widget = container

    if (state.instanceKey != configKey || state.hyperswitchInstance == null) {
      clearWidget(state, removeWidget = false)
      state.hyperswitchInstance = Hyperswitch.init(
        activity = activity,
        config = HyperswitchConfiguration(
          publishableKey = publishableKey,
          profileId = profileId,
        )
      )
      state.instanceKey = configKey
    } else {
      clearWidget(state, removeWidget = false)
    }

    val sessionConfig = PaymentSessionConfiguration(sdkAuthorization)
    state.hyperswitchInstance?.elements(sessionConfig) { elements ->
      if (viewStates[container] !== state) {
        return@elements
      }
      state.elements = elements

      container.setSubscribedEvents(subscribedEvents(props.optionsMap))
      container.setOnEventCallback(object : PaymentEventListener {
        override fun onPaymentEvent(event: PaymentEvent) {
          emitOnPaymentEvent(container, event)
        }
      })

      state.widgetBound = elements.bind(container, props.optionsMap ?: emptyMap())
      container.type = PAYMENT_ELEMENT_TYPE
    }
  }

  private fun clearWidget(state: WidgetState, removeWidget: Boolean) {
    state.widgetBound?.let { widget ->
      state.elements?.unbind(widget)
    }
    state.elements = null

    if (removeWidget) {
      state.widget?.destroy()
      (state.widget?.parent as? HyperswitchElement)?.removeView(state.widget)
      state.widget = null
    }
  }

  private fun stateFor(container: HyperswitchElement): WidgetState =
    viewStates.getOrPut(container) { WidgetState() }

  private fun subscribedEvents(optionsMap: Map<String, Any?>?): List<String> {
    val events = optionsMap?.get("subscribedEvents") as? List<*> ?: return emptyList()
    return events.mapNotNull { it as? String }
  }

  @Suppress("UNCHECKED_CAST")
  private fun emitOnPaymentEvent(container: HyperswitchElement, event: PaymentEvent) {
    val payloadMap = Arguments.makeNativeMap(event.payload as Map<String, Object>)
    val eventData = Arguments.createMap().apply {
      putString("eventName", event.type)
      putMap("payload", payloadMap)
    }
    context?.runOnUiQueueThread {
      context?.getJSModule(RCTEventEmitter::class.java)
        ?.receiveEvent(container.id, "topOnPaymentEvent", eventData)
    }
  }

  override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any>? {
    return com.facebook.react.common.MapBuilder.of(
      "topOnPaymentEvent",
      com.facebook.react.common.MapBuilder.of("registrationName", "onPaymentEvent")
    )
  }

  private fun ReadableMap.getStringOrNull(key: String): String? =
    if (hasKey(key) && !isNull(key)) getString(key) else null

  private fun readableMapToMap(map: ReadableMap): Map<String, Any?> {
    val result = mutableMapOf<String, Any?>()
    val iterator = map.entryIterator
    while (iterator.hasNext()) {
      val entry = iterator.next()
      result[entry.key] = when (val value = entry.value) {
        is ReadableMap -> readableMapToMap(value)
        is ReadableArray -> readableArrayToList(value)
        else -> value
      }
    }
    return result
  }

  private fun readableArrayToList(array: ReadableArray): List<Any?> =
    (0 until array.size()).map { index ->
      val value = array.getDynamic(index)
      when (value.type) {
        com.facebook.react.bridge.ReadableType.Null -> null
        com.facebook.react.bridge.ReadableType.Boolean -> value.asBoolean()
        com.facebook.react.bridge.ReadableType.Number -> value.asDouble()
        com.facebook.react.bridge.ReadableType.String -> value.asString()
        com.facebook.react.bridge.ReadableType.Map -> readableMapToMap(value.asMap())
        com.facebook.react.bridge.ReadableType.Array -> readableArrayToList(value.asArray())
      }
    }

  private class NativeWidgetContainer(activity: Activity?) : HyperswitchElement(activity!!) {
    override fun requestLayout() {
      super.requestLayout()
      post(measureAndLayout)
    }

    private val measureAndLayout = Runnable {
      measure(
        MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY),
        MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY)
      )
      layout(left, top, right, bottom)
    }
  }

  private data class WidgetState(
    val props: WidgetProps = WidgetProps(),
    var hyperswitchInstance: HyperswitchInstance? = null,
    var elements: Elements? = null,
    var widget: HyperswitchElement? = null,
    var widgetBound: HyperswitchBoundElement? = null,
    var instanceKey: String? = null,
  ) {
    fun hasWidget(): Boolean = widget != null
  }

  private data class WidgetProps(
    var widgetType: String? = null,
    var sdkAuthorization: String? = null,
    var optionsSdkAuthorization: String? = null,
    var publishableKey: String? = null,
    var profileId: String? = null,
    var optionsMap: Map<String, Any?>? = null,
  ) {
    fun effectiveSdkAuthorization(): String? =
      sdkAuthorization?.takeIf { it.isNotBlank() }
        ?: optionsSdkAuthorization?.takeIf { it.isNotBlank() }
        ?: HyperswitchRNWrapperNativeModule.getActiveSdkAuthorization()?.takeIf { it.isNotBlank() }

    fun effectivePublishableKey(): String? =
      publishableKey?.takeIf { it.isNotBlank() }
        ?: HyperswitchRNWrapperNativeModule.getActivePublishableKey()?.takeIf { it.isNotBlank() }

    fun effectiveProfileId(): String? =
      profileId?.takeIf { it.isNotBlank() }
        ?: HyperswitchRNWrapperNativeModule.getActiveProfileId()?.takeIf { it.isNotBlank() }

    fun isCvcWidget(): Boolean = widgetType == CVC_WIDGET

    fun isPaymentWidget(): Boolean =
      widgetType == PAYMENT_ELEMENT ||
        widgetType == WIDGET_PAYMENT_SHEET

    fun isSupportedWidgetType(): Boolean = isCvcWidget() || isPaymentWidget()
  }

  companion object {
    const val NAME = "NativePaymentWidget"
    private const val CVC_WIDGET = "cvcWidget"
    private const val PAYMENT_ELEMENT = "paymentElement"
    private const val WIDGET_PAYMENT_SHEET = "widgetPaymentSheet"
    private const val PAYMENT_ELEMENT_TYPE = "payment"
  }
}
