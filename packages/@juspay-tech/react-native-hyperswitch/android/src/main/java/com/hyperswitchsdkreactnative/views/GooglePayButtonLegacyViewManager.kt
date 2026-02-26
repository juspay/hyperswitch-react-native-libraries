package com.hyperswitchsdkreactnative.views

import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.google.android.gms.wallet.button.ButtonConstants

class GooglePayButtonLegacyViewManager :
  SimpleViewManager<GooglePayButtonView>() {

  override fun getName(): String {
    return NAME
  }

  override fun createViewInstance(
    context: ThemedReactContext
  ): GooglePayButtonView {
    return GooglePayButtonView(context)
  }

  override fun onAfterUpdateTransaction(view: GooglePayButtonView) {
    super.onAfterUpdateTransaction(view)
    view.addButton()
  }

  @ReactProp(name = "buttonType")
  fun setButtonType(view: GooglePayButtonView, value: String?) {
    view.type = when (value) {
      "BUY" -> ButtonConstants.ButtonType.BUY
      "BOOK" -> ButtonConstants.ButtonType.BOOK
      "CHECKOUT" -> ButtonConstants.ButtonType.CHECKOUT
      "DONATE" -> ButtonConstants.ButtonType.DONATE
      "ORDER" -> ButtonConstants.ButtonType.ORDER
      "PAY" -> ButtonConstants.ButtonType.PAY
      "SUBSCRIBE" -> ButtonConstants.ButtonType.SUBSCRIBE
      else -> ButtonConstants.ButtonType.PLAIN
    }
  }

  @ReactProp(name = "buttonStyle")
  fun setButtonStyle(view: GooglePayButtonView, value: String?) {
    view.theme = when (value) {
      "light" -> ButtonConstants.ButtonTheme.LIGHT
      else -> ButtonConstants.ButtonTheme.DARK
    }
  }

  @ReactProp(name = "borderRadius", defaultDouble = 0.0)
  fun setBorderRadius(view: GooglePayButtonView, value: Double) {
    view.cornerRadius = value.toInt()
  }

  @ReactProp(name = "allowedPaymentMethods")
  fun setAllowedPaymentMethods(view: GooglePayButtonView, value: String?) {
    value?.let {
      view.allowedPaymentMethods = it
    }
  }

  companion object {
    const val NAME = "GooglePayButton"
  }
}
