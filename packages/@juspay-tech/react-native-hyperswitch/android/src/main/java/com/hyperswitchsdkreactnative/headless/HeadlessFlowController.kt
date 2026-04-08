package com.hyperswitchsdkreactnative.headless

import android.app.Application
import com.hyperswitchsdkreactnative.BuildConfig
import com.hyperswitchsdkreactnative.provider.HyperProvider
import com.hyperswitchsdkreactnative.provider.LaunchOptions

/**
 * Orchestration layer for the headless payment flow in the RN wrapper.
 *
 * This is NOT part of the common library — it is wrapper-specific glue code that:
 * 1. Starts HeadlessJsTask to fetch saved payment methods
 * 2. Wires GetPaymentSessionCallBackManager to deliver the handler to the merchant
 *
 * CvcWidget confirm routing is handled by HyperFragment.confirmCvcPayment + ExitHeadlessCallBackManager.
 *
 * The common library files (HyperHeadlessModule, PaymentSessionHandler, PaymentResult, etc.)
 * handle the JS bridge interaction and data parsing.
 */
object HeadlessFlowController {

    private var headlessCompletion: ((PaymentSessionHandler) -> Unit)? = null

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
     * Full reset. Called when CvcWidget is dropped (onDropViewInstance) or re-initializing.
     */
    @Synchronized
    fun reset() {
        headlessCompletion = null
    }
}
