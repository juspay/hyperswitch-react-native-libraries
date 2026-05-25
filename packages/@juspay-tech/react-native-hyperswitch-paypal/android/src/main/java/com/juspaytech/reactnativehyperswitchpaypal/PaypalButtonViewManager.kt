package com.juspaytech.reactnativehyperswitchpaypal

import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.paypal.android.paymentbuttons.PayPalButtonColor
import com.paypal.android.paymentbuttons.PayPalButtonLabel
import com.paypal.android.paymentbuttons.PaymentButtonSize

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
      "GOLD" -> PayPalButtonColor.GOLD
      "BLUE" -> PayPalButtonColor.BLUE
      "SILVER" -> PayPalButtonColor.SILVER
      "WHITE" -> PayPalButtonColor.WHITE
      "BLACK" -> PayPalButtonColor.BLACK
      else -> PayPalButtonColor.GOLD
    }
  }

  @ReactProp(name = "buttonLabel")
  fun setButtonLabel(view: PaypalButtonView, value: String?) {
    view.buttonLabel = when (value) {
      "CHECKOUT" -> PayPalButtonLabel.CHECKOUT
      "BUY_NOW" -> PayPalButtonLabel.BUY_NOW
      "PAY" -> PayPalButtonLabel.PAY
      else -> PayPalButtonLabel.PAYPAL
    }
  }

  @ReactProp(name = "buttonSize")
  fun setButtonSize(view: PaypalButtonView, value: String?) {
    view.buttonSize = when (value) {
      "SMALL" -> PaymentButtonSize.SMALL
      "LARGE" -> PaymentButtonSize.LARGE
      else -> PaymentButtonSize.MEDIUM
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
