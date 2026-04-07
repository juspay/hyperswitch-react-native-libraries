package com.hyperswitchsdkreactnative.headless

import android.app.Application
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.internal.featureflags.ReactNativeFeatureFlags
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.hyperswitchsdkreactnative.BuildConfig
import com.hyperswitchsdkreactnative.provider.HyperProvider
import com.hyperswitchsdkreactnative.provider.LaunchOptions
import com.hyperswitchsdkreactnative.provider.ReactNativeController

/**
 * Orchestration layer for the headless payment flow in the RN wrapper.
 *
 * This is NOT part of the common library — it is wrapper-specific glue code that:
 * 1. Starts HeadlessJsTask to fetch saved payment methods
 * 2. Wires GetPaymentSessionCallBackManager to deliver the handler to the merchant
 * 3. Routes CvcWidget confirms via DeviceEventEmitter
 * 4. Manages confirm state (hasResponded guard, confirmCompletion callback)
 *
 * The common library files (HyperHeadlessModule, PaymentSessionHandler, PaymentResult, etc.)
 * handle the JS bridge interaction and data parsing.
 */
object HeadlessFlowController {

    private var headlessCompletion: ((PaymentSessionHandler) -> Unit)? = null
    private var confirmCompletion: ((PaymentResult) -> Unit)? = null
    private var hasResponded = false

    /**
     * Starts the headless flow to get customer saved payment methods.
     * Always starts HeadlessJsTask — CvcWidget is never involved in the get flow.
     *
     * @param clientSecret The payment intent client secret
     * @param application The application context
     * @param callback Invoked with the PaymentSessionHandler when payment methods are ready
     */
    @Synchronized
    fun getCustomerSavedPaymentMethods(
        clientSecret: String,
        application: Application,
        callback: (PaymentSessionHandler) -> Unit
    ) {
        hasResponded = false
        headlessCompletion = callback

        // Wire the callback manager so that when HyperHeadlessModule.getPaymentSession()
        // creates the handler, it gets delivered to our headlessCompletion
        GetPaymentSessionCallBackManager.setCallback { handler ->
            headlessCompletion?.invoke(handler)
            headlessCompletion = null
        }

        val launchOptions = LaunchOptions(application, BuildConfig.VERSION_NAME)

        val props = launchOptions.getBundle(
            publishableKey = HyperProvider.publishableKey,
            clientSecret = clientSecret,
            customBackendUrl = HyperProvider.customBackendUrl,
            customLogUrl = HyperProvider.customLogUrl,
            customParams = HyperProvider.customParams,
            type = "headless"
        )

        HeadlessManager.startHeadlessTask(props, application)
    }

    /**
     * Routes a card confirm through CvcWidget's JS context by emitting a "confirmPayment" event.
     * CvcWidget JS listens for this event, reads CVC from CvcRegistry, and calls confirmAPICall.
     * CVC never crosses the bridge — it stays in CvcWidget's JS memory.
     *
     * @param widgetId Which CvcWidget's CVC to use
     * @param paymentToken The payment token for the saved payment method
     * @param resultHandler Callback to invoke with the payment result (called when exitHeadless fires)
     */
    @Synchronized
    fun confirmViaWidget(
        widgetId: String,
        paymentToken: String,
        paymentMethodId: String,
        resultHandler: (PaymentResult) -> Unit
    ) {
        if (hasResponded) {
            return
        }
        hasResponded = true

        // Wire ExitHeadlessCallBackManager so exitHeadless() routes back to our resultHandler
        ExitHeadlessCallBackManager.setCallback(resultHandler)
        confirmCompletion = resultHandler

        val reactContext = getReactContext()
        if (reactContext == null) {
            confirmCompletion = null
            hasResponded = false
            val throwable = Throwable("ReactContext not available for CvcWidget confirm")
            throwable.initCause(Throwable("NO_CONTEXT"))
            resultHandler(PaymentResult.Failed(throwable))
            return
        }

        try {
            val payload = Arguments.createMap().apply {
                putString("paymentToken", paymentToken)
                putString("paymentMethodId", paymentMethodId)
                putString("widgetId", widgetId)
            }
            reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                ?.emit("confirmPayment", payload)
        } catch (e: Exception) {
            confirmCompletion = null
            hasResponded = false
            val throwable = Throwable("Failed to emit confirmPayment event: ${e.message}")
            throwable.initCause(Throwable("EMIT_ERROR"))
            resultHandler(PaymentResult.Failed(throwable))
        }
    }

    /**
     * Resets just the confirm guard so the widget accepts the next confirm call.
     * Called by HyperHeadlessModule.exitHeadless() after delivering the result.
     */
    @Synchronized
    fun resetConfirmState() {
        hasResponded = false
        confirmCompletion = null
    }

    /**
     * Full reset. Called when CvcWidget is dropped (onDropViewInstance) or re-initializing.
     */
    @Synchronized
    fun reset() {
        confirmCompletion = null
        hasResponded = false
    }

    private fun getReactContext(): ReactContext? {
        return try {
            if (!ReactNativeController.getIsInitialized()) return null
            if (ReactNativeFeatureFlags.enableBridgelessArchitecture()) {
                ReactNativeController.getReactHost().currentReactContext
            } else {
                ReactNativeController.getReactNativeHost().reactInstanceManager?.currentReactContext
            }
        } catch (_: Exception) {
            null
        }
    }
}
