package com.juspaytech.reactnativehyperswitchpaypal

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.WindowManager
import com.paypal.android.corepayments.CoreConfig
import com.paypal.android.corepayments.Environment
import com.paypal.android.paypalwebpayments.PayPalPresentAuthChallengeResult
import com.paypal.android.paypalwebpayments.PayPalWebCheckoutClient
import com.paypal.android.paypalwebpayments.PayPalWebCheckoutFinishStartResult
import com.paypal.android.paypalwebpayments.PayPalWebCheckoutFundingSource
import com.paypal.android.paypalwebpayments.PayPalWebCheckoutRequest

class PayPalRedirectActivity : Activity() {

    private var payPalClient: PayPalWebCheckoutClient? = null
    private var callbackInvoked = false
    private var browserLaunched = false

    override fun onCreate(savedInstanceState: Bundle?) {
        // Skip enter animation
        overridePendingTransition(0, 0)

        // Make window completely invisible
        window.setFlags(
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
        )
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT

        super.onCreate(savedInstanceState)

        val params = intent?.extras ?: run {
            Log.e(TAG, "No parameters provided")
            finish()
            return
        }

        val clientId = params.getString("clientId") ?: run {
            notifyFailure("Missing clientId", null)
            return
        }
        val orderId = params.getString("orderId") ?: run {
            notifyFailure("Missing orderId", null)
            return
        }
        val environmentStr = params.getString("environment", "SANDBOX")
        val returnUrl = params.getString("returnUrl", "${packageName}.paypal")
        val fundingSourceStr = params.getString("fundingSource", "PAYPAL")

        val environment = if (environmentStr == "PRODUCTION") Environment.LIVE else Environment.SANDBOX
        val fundingSource = when (fundingSourceStr) {
            "PAY_LATER" -> PayPalWebCheckoutFundingSource.PAY_LATER
            "PAYPAL_CREDIT" -> PayPalWebCheckoutFundingSource.PAYPAL_CREDIT
            else -> PayPalWebCheckoutFundingSource.PAYPAL
        }

        Log.d(TAG, "Starting PayPal checkout - orderId: $orderId, returnUrl: $returnUrl")

        val config = CoreConfig(clientId, environment = environment)
        payPalClient = PayPalWebCheckoutClient(this, config, returnUrl)

        val request = PayPalWebCheckoutRequest(orderId, fundingSource = fundingSource)

        payPalClient?.start(this, request) { startResult ->
            when (startResult) {
                is PayPalPresentAuthChallengeResult.Success -> {
                    Log.d(TAG, "PayPal browser launched successfully")
                    browserLaunched = true
                }
                is PayPalPresentAuthChallengeResult.Failure -> {
                    Log.e(TAG, "PayPal start failed: ${startResult.error.errorDescription}")
                    notifyFailure(
                        startResult.error.errorDescription ?: "Failed to start PayPal",
                        startResult.error.code?.toString()
                    )
                }
            }
        }
    }

    override fun finish() {
        super.finish()
        // Skip exit animation
        overridePendingTransition(0, 0)
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent called")

        if (callbackInvoked) return

        intent?.let {
            val result = payPalClient?.finishStart(it)
            handleFinishResult(result)
        }
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "onResume called - browserLaunched: $browserLaunched, callbackInvoked: $callbackInvoked")

        // If browser was launched but no deep link received (callbackInvoked is false),
        // user cancelled by closing the browser
        if (browserLaunched && !callbackInvoked) {
            // Small delay to ensure onNewIntent didn't just fire
            Handler(Looper.getMainLooper()).postDelayed({
                if (!callbackInvoked) {
                    Log.d(TAG, "User cancelled - no deep link received")
                    notifyCancelled()
                }
            }, 300)
        }
    }

    private fun handleFinishResult(result: PayPalWebCheckoutFinishStartResult?) {
        when (result) {
            is PayPalWebCheckoutFinishStartResult.Success -> {
                Log.d(TAG, "PayPal success - orderId: ${result.orderId}, payerId: ${result.payerId}")
                notifySuccess(result.orderId ?: "", result.payerId ?: "")
            }
            is PayPalWebCheckoutFinishStartResult.Failure -> {
                Log.e(TAG, "PayPal failure - error: ${result.error.errorDescription}")
                notifyFailure(
                    result.error.errorDescription ?: result.error.message ?: "Unknown PayPal error",
                    result.error.code?.toString()
                )
            }
            is PayPalWebCheckoutFinishStartResult.Canceled -> {
                Log.d(TAG, "PayPal cancelled (from deep link)")
                notifyCancelled()
            }
            PayPalWebCheckoutFinishStartResult.NoResult -> {
                Log.d(TAG, "NoResult from finishStart")
            }
            null -> {
                Log.d(TAG, "finishStart returned null")
            }
        }
    }

    private fun notifySuccess(orderId: String, payerId: String) {
        if (callbackInvoked) return
        callbackInvoked = true
        PayPalPendingResult.notifySuccess(orderId, payerId)
        finish()
    }

    private fun notifyCancelled() {
        if (callbackInvoked) return
        callbackInvoked = true
        PayPalPendingResult.notifyCancelled()
        finish()
    }

    private fun notifyFailure(errorMessage: String, errorCode: String?) {
        if (callbackInvoked) return
        callbackInvoked = true
        PayPalPendingResult.notifyFailure(errorMessage, errorCode)
        finish()
    }

    companion object {
        private const val TAG = "PayPalRedirect"
    }
}
