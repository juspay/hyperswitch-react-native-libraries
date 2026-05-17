package com.juspaytech.reactnativehyperswitchpaypal

import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.paypal.android.paymentbuttons.PayPalButtonColor
import com.paypal.android.paymentbuttons.PayPalButtonLabel

@ReactModule(name = PaypalButtonViewManager.NAME)
class PaypalButtonViewManager : SimpleViewManager<PaypalButtonView>() {

  override fun getName(): String {
    return NAME
  }

  public override fun createViewInstance(context: ThemedReactContext): PaypalButtonView {
    return PaypalButtonView(context)
  }

  public override fun onAfterUpdateTransaction(view: PaypalButtonView) {
    super.onAfterUpdateTransaction(view)
    view.addButton()
  }

  @ReactProp(name = "buttonColor")
  fun setButtonColor(view: PaypalButtonView, value: String?) {
    view.buttonColor = when (value) {
      "gold" -> PayPalButtonColor.GOLD
      "blue" -> PayPalButtonColor.BLUE
      "silver" -> PayPalButtonColor.SILVER
      "white" -> PayPalButtonColor.WHITE
      "black" -> PayPalButtonColor.BLACK
      else -> PayPalButtonColor.GOLD
    }
  }

  @ReactProp(name = "buttonLabel")
  fun setButtonLabel(view: PaypalButtonView, value: String?) {
    view.buttonLabel = when (value) {
      "checkout" -> PayPalButtonLabel.CHECKOUT
      "buynow" -> PayPalButtonLabel.BUY_NOW
      "pay" -> PayPalButtonLabel.PAY
      else -> PayPalButtonLabel.PAYPAL
    }
  }

  @ReactProp(name = "borderRadius", defaultDouble = 0.0)
  fun setBorderRadius(view: PaypalButtonView, value: Double) {
    view.customCornerRadius = value.toFloat()
  }

  companion object {
    const val NAME = "PaypalButton"
  }
}
