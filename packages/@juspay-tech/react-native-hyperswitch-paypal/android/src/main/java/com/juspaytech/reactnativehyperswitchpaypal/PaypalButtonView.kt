package com.juspaytech.reactnativehyperswitchpaypal

import android.annotation.SuppressLint
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import com.facebook.react.uimanager.ThemedReactContext
import com.paypal.android.paymentbuttons.PayPalButton
import com.paypal.android.paymentbuttons.PayPalButtonColor
import com.paypal.android.paymentbuttons.PayPalButtonLabel
import com.paypal.android.paymentbuttons.PaymentButtonSize

@SuppressLint("ViewConstructor")
class PaypalButtonView(private val context: ThemedReactContext) : FrameLayout(context) {

  var buttonColor: PayPalButtonColor = PayPalButtonColor.GOLD
  var buttonLabel: PayPalButtonLabel = PayPalButtonLabel.PAYPAL
  var buttonSize: PaymentButtonSize = PaymentButtonSize.MEDIUM
  var customCornerRadius: Float = 10.0F
  private var button: PayPalButton? = null

  fun addButton() {
    if (button != null) {
      removeView(button)
    }
    button = initializePayPalButton()
    addView(button)
    viewTreeObserver.addOnGlobalLayoutListener { requestLayout() }
  }

  private fun initializePayPalButton(): PayPalButton {
    val payPalButton = PayPalButton(context)

    payPalButton.color = buttonColor
    payPalButton.label = buttonLabel
    payPalButton.size = buttonSize
    payPalButton.customCornerRadius = customCornerRadius
    payPalButton.setOnClickListener {
      (this.parent as? View)?.performClick() ?: run {
        Log.e("PaypalButtonView", "Unable to find parent of PaypalButtonView.")
      }
    }

    return payPalButton
  }

  override fun requestLayout() {
    super.requestLayout()
    post(mLayoutRunnable)
  }

  private val mLayoutRunnable = Runnable {
    measure(
      MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY),
      MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY)
    )
    layout(left, top, right, bottom)
  }
}
