package com.hyperswitchsdkreactnative.views

import android.app.Application
import android.content.Context
import android.os.Bundle
import android.util.AttributeSet
import android.widget.FrameLayout
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReadableMap
import com.hyperswitchsdkreactnative.BuildConfig
import com.hyperswitchsdkreactnative.provider.HyperProvider
import com.hyperswitchsdkreactnative.utils.EventCallback
import com.hyperswitchsdkreactnative.provider.LaunchOptions
import com.hyperswitchsdkreactnative.provider.ReactNativeController
import com.hyperswitchsdkreactnative.utils.WidgetCallbackManager
import java.util.UUID

class PaymentWidgetView : FrameLayout {
  private var configuration: ReadableMap? = null
  private lateinit var launchOptions: LaunchOptions
  private var callback: Callback? = null
  private lateinit var context: Context
  private var publishableKey: String? = null
  private var profileId: String? = null
  private var widgetId = UUID.randomUUID().toString()
  private var clientSecret: String = ""
  private var widgetType: String? = null

  fun getConfiguration(): ReadableMap?{
    return this.configuration
  }

  fun getClientSecret():String{
    return this.clientSecret
  }



  fun setWidgetId(widgetId: String) {
    this.widgetId = widgetId
  }


  constructor(context: Context?) : super(context!!) {
    init(context)
  }

  constructor(context: Context, attrs: AttributeSet?) : super(context, attrs) {
    init(context)
  }

  constructor(
    context: Context, attrs: AttributeSet?, defStyleAttr: Int
  ) : super(context, attrs, defStyleAttr) {
    init(context)
  }

  private fun init(context: Context) {
    this.context = context
    launchOptions = LaunchOptions(context.applicationContext, BuildConfig.VERSION_NAME)
    this.publishableKey = HyperProvider.publishableKey
  }

  fun initWidget(publishableKey: String) {
    initWidget(publishableKey, this.profileId ?: "")
  }

  fun initWidget(
    publishableKey: String, profileId: String
  ) {
    initWidget(
      context.applicationContext as Application, "widgetPaymentSheet", publishableKey, profileId
    )
  }

  fun initWidget(
    application: Application,
    type: String,
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
  fun setWidgetType(widgetType: String?) {
    this.widgetType = widgetType
  }


  fun configuration(configuration: ReadableMap) {
    this.configuration = configuration
  }

  fun onPaymentResult(callback: Callback) {
    this.callback = callback
    WidgetCallbackManager.setCallback(callback, true, this.widgetId)
  }

  fun onEvent(eventCallback: EventCallback) {
    WidgetCallbackManager.setEventCallback(this.widgetId, eventCallback)
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    initWidget(HyperProvider.publishableKey ?: "")
  }

  fun getLaunchOptions() : Bundle =
    this.launchOptions.getBundle(
      publishableKey = HyperProvider.publishableKey,
      clientSecret = this.clientSecret,
      configuration = this.getConfiguration(),
      customBackendUrl = HyperProvider.customBackendUrl,
      customLogUrl = HyperProvider.customLogUrl,
      customParams = HyperProvider.customParams,
      type = widgetType,
      widgetId = this.widgetId
    )


  fun setPaymentIntent(clientSecret: String) {
    this.clientSecret = clientSecret
  }
}
