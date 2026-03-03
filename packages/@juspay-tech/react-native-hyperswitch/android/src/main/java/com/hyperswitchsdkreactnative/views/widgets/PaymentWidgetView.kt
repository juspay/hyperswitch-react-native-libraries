package com.hyperswitchsdkreactnative.views.widgets

import android.app.Application
import android.content.Context
import android.os.Bundle
import android.util.Log
import android.widget.FrameLayout
import androidx.fragment.app.FragmentActivity
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.events.RCTEventEmitter
import com.hyperswitchsdkreactnative.BuildConfig
import com.hyperswitchsdkreactnative.PaymentSheetResult
import com.hyperswitchsdkreactnative.provider.HyperProvider
import com.hyperswitchsdkreactnative.utils.EventCallback
import com.hyperswitchsdkreactnative.react.HyperFragment
import com.hyperswitchsdkreactnative.react.LaunchOptions
import com.hyperswitchsdkreactnative.react.ReactNativeController
import com.hyperswitchsdkreactnative.utils.WidgetCallbackManager
import org.json.JSONObject
import java.util.UUID

enum class WidgetType {
  PAYMENT_SHEET, BUTTON_SHEET, CARD, EXPRESS_CHECKOUT, GOOGLE_PAY, PAYPAL;


  companion object {
    fun from(value: String?): WidgetType {
      return try {
        WidgetType.valueOf(value?.uppercase() ?: "ERROR")
      } catch (_: IllegalArgumentException) {
        PAYMENT_SHEET
      }
    }
  }
}

typealias Callback = (PaymentSheetResult) -> Unit

class PaymentWidgetView : FrameLayout {
  private var configuration: String = ""
  private lateinit var launchOptions: LaunchOptions
  private var callback: Callback? = { it ->  }
  private lateinit var context: Context
  private var publishableKey: String? = null
  private var profileId: String? = null
  private var widgetId = UUID.randomUUID().toString()
  private var clientSecret: String = ""

  fun getConfiguration():String{
    return this.configuration
  }

  private var widgetType = WidgetType.PAYMENT_SHEET

  fun setWidgetId(widgetId: String) {
    this.widgetId = widgetId
  }


  constructor(context: Context?) : super(context!!) {
    init(context)
  }

  constructor(context: Context, attrs: android.util.AttributeSet?) : super(context, attrs) {
    init(context)
  }

  constructor(
    context: Context, attrs: android.util.AttributeSet?, defStyleAttr: Int
  ) : super(context, attrs, defStyleAttr) {
    init(context)
  }

  private fun init(context: Context) {
    this.context = context
    launchOptions = LaunchOptions(context.applicationContext, BuildConfig.VERSION_NAME)
    this.publishableKey = HyperProvider.publishableKey()
  }

  fun initWidget(publishableKey: String) {
    initWidget(publishableKey, this.profileId ?: "")
  }

  fun initWidget(
    publishableKey: String, profileId: String
  ) {
    initWidget(
      context.applicationContext as Application, WidgetType.PAYMENT_SHEET, publishableKey, profileId
    )
  }

  fun initWidget(
    application: Application,
    type: WidgetType,
    publishableKey: String,
    profileId: String,
  ) {
    this.widgetType = type
    this.publishableKey = publishableKey
    this.profileId = profileId
    ReactNativeController.initialize(application)
  }


  fun isClientSecretEmpty():Boolean {
    return this.clientSecret.isEmpty()
  }
  fun setWidgetType(widgetType: WidgetType) {
    this.widgetType = widgetType
  }


  fun configuration(configuration: String) {
    this.configuration = configuration
  }

  fun onPaymentResult(callback: Callback) {
    this.callback = callback
    val mCallback: Callback = { result ->
      callback(result)
    }
    WidgetCallbackManager.setCallback(mCallback, true, this.widgetId)
  }

  fun onEvent(eventCallback: EventCallback) {
    WidgetCallbackManager.setEventCallback(this.widgetId, eventCallback)
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    initWidget(HyperProvider.publishableKey())
  }

  private fun getFragmentActivity(): FragmentActivity? {
    var ctx = context
    while (ctx is android.content.ContextWrapper) {
      if (ctx is FragmentActivity) {
        return ctx
      }
      ctx = ctx.baseContext
    }
    return null
  }

  private fun getWidgetType(): String {
    return when (this.widgetType) {
      WidgetType.PAYMENT_SHEET -> "widgetPaymentSheet"
      WidgetType.BUTTON_SHEET -> "widgetButtonSheet"
      WidgetType.CARD -> "card"
      WidgetType.EXPRESS_CHECKOUT -> "expressCheckout"
      WidgetType.GOOGLE_PAY -> "google_pay"
      WidgetType.PAYPAL -> "paypal"
      else -> "widgetPaymentSheet"
    }
  }

  fun getLaunchOptions() : Bundle{
    return this.launchOptions.getBundle(
      paymentIntentClientSecret = this.clientSecret,
        configuration = this.getConfiguration(),
        type = this.getWidgetType(),
      widgetId = this.widgetId
    )
  }


  fun setPaymentIntent(clientSecret: String) {
    this.clientSecret = clientSecret
  }
}
