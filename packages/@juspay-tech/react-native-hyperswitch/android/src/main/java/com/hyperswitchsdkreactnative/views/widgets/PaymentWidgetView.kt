package com.hyperswitchsdkreactnative.views.widgets

import android.app.Application
import android.content.Context
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import androidx.fragment.app.FragmentActivity
import com.hyperswitchsdkreactnative.BuildConfig
import com.hyperswitchsdkreactnative.PaymentSheetResult
import com.hyperswitchsdkreactnative.provider.HyperProvider
import com.hyperswitchsdkreactnative.react.EventCallback
import com.hyperswitchsdkreactnative.react.HyperFragment
import com.hyperswitchsdkreactnative.react.LaunchOptions
import com.hyperswitchsdkreactnative.react.ReactNativeController
import com.hyperswitchsdkreactnative.react.WidgetCallbackManager
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
  private var callback: Callback? = { it -> Log.i("Manideep", it.toString()) }
  private var publishableKey: String? = null
  private var profileId: String? = null
  private var sessionId = UUID.randomUUID().toString()
  private var clientSecret: String = ""

  fun getClientSecret() :String{
   return  this.clientSecret
  }

  fun getConfiguration():String{
    return this.configuration
  }

  private var widgetType = WidgetType.PAYMENT_SHEET

  // Internal container for the fragment
  private lateinit var fragmentContainer: FrameLayout

  fun setSessionId(sessionId: String) {
    this.sessionId = sessionId
  }


  constructor(context: Context?) : super(context!!) {
    init()
  }

  constructor(context: Context, attrs: android.util.AttributeSet?) : super(context, attrs) {
    init()
  }

  constructor(
    context: Context, attrs: android.util.AttributeSet?, defStyleAttr: Int
  ) : super(context, attrs, defStyleAttr) {
    init()
  }

  private fun init() {
//    fragmentContainer = FrameLayout(context).apply {
//      id = View.generateViewId()
//    }
//    addView(fragmentContainer)
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

  fun setWidgetType(widgetType: WidgetType) {
    this.widgetType = widgetType
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

  fun configuration(configuration: String) {
    this.configuration = configuration
  }

  fun onPaymentResult(callback: Callback) {
    this.callback = callback
    val mCallback: Callback = { result ->
      callback(result)
      Log.i("Manideep", "Called back")
      removeWidget()
    }
    WidgetCallbackManager.setCallback(mCallback, true, this.sessionId)
  }

  fun onEvent(eventCallback: EventCallback) {
    WidgetCallbackManager.setEventCallback(this.sessionId, eventCallback)
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    initWidget(HyperProvider.publishableKey())
    showWidget()
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

  fun showWidget(clientSecret: String, callback: Callback? = null) {
    this.clientSecret = clientSecret
    callback?.let { this.callback = it }

//    if (!isAttachedToWindow) {
//      post { showWidgetInternal() }
//    } else {
//      showWidgetInternal()
//    }
  }
  fun showWidget(clientSecret: String) {
    this.clientSecret = clientSecret
    showWidget(clientSecret, this.callback)
  }

  fun showWidget() {
    showWidget(this.clientSecret, this.callback)
  }

  fun setPaymentIntent(clientSecret: String) {
    this.clientSecret = clientSecret
  }

  private fun removeWidget() {
    val activity = getFragmentActivity() ?: return

    val fragment =
      activity.supportFragmentManager.findFragmentById(id)
        as? HyperFragment ?: return

    WidgetCallbackManager.removeSession(this.sessionId)

    activity.supportFragmentManager.beginTransaction()
      .remove(fragment)
      .commitAllowingStateLoss()
  }
}
