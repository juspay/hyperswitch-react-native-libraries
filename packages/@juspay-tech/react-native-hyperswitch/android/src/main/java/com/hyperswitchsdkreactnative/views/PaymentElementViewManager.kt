package com.hyperswitchsdkreactnative.views

import android.app.Activity
import com.facebook.react.bridge.Dynamic
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.NativePaymentWidgetManagerInterface
import com.facebook.react.viewmanagers.NativePaymentWidgetManagerDelegate
import io.hyperswitch.view.PaymentWidgetView

class PaymentElementViewManager : SimpleViewManager<PaymentWidgetView>(),
  NativePaymentWidgetManagerInterface<PaymentWidgetView> {

  private val mDelegate: ViewManagerDelegate<PaymentWidgetView> =
    NativePaymentWidgetManagerDelegate(this)

  override fun getName(): String = NAME

  override fun getDelegate(): ViewManagerDelegate<PaymentWidgetView> {
    return mDelegate
  }

  private var context: ReactApplicationContext? = null

  override fun createViewInstance(reactContext: ThemedReactContext): PaymentWidgetView {
    context = reactContext.reactApplicationContext
    return NativeWidgetContainer(context?.currentActivity)
  }

  override fun onAfterUpdateTransaction(container: PaymentWidgetView) {
    super.onAfterUpdateTransaction(container)
  }

  @ReactProp(name = "widgetType")
  override fun setWidgetType(container: PaymentWidgetView, widgetType: String?) {
    container.setWidgetType(widgetType)
  }

  @ReactProp(name = "sdkAuthorization")
  override fun setSdkAuthorization(container: PaymentWidgetView, sdkAuthorization: String?) {
    sdkAuthorization?.let {
      container.setSdkAuthorization(sdkAuthorization)
    }
  }

  @ReactProp(name = "options")
  override fun setOptions(container: PaymentWidgetView, options: Dynamic?) {
    options?.asMap()?.let {
      container.setConfiguration(it)
    }
  }


//  @Suppress("UNCHECKED_CAST")
//  private fun emitOnPaymentEvent(container: PaymentWidgetView, event: PaymentEvent) {
//    val payloadMap = Arguments.makeNativeMap(event.payload as Map<String, Object>)
//    val eventData = Arguments.createMap().apply {
//      putString("eventName", event.type)
//      putMap("payload", payloadMap)
//    }
//    context?.runOnUiQueueThread {
//      context?.getJSModule(RCTEventEmitter::class.java)
//        ?.receiveEvent(container.id, "topOnPaymentEvent", eventData)
//    }
//  }

  override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any>? {
    return com.facebook.react.common.MapBuilder.of(
      "onPaymentEvent",
      com.facebook.react.common.MapBuilder.of("registrationName", "onPaymentEvent")
    )
  }

  private class NativeWidgetContainer(activity: Activity?) : PaymentWidgetView(activity!!) {
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

  companion object {
    const val NAME = "RCTNativePaymentWidget"
    private const val CVC_WIDGET = "cvcWidget"
    private const val PAYMENT_ELEMENT = "paymentElement"
    private const val WIDGET_PAYMENT_SHEET = "widgetPaymentSheet"
    private const val PAYMENT_ELEMENT_TYPE = "payment"
  }
}
