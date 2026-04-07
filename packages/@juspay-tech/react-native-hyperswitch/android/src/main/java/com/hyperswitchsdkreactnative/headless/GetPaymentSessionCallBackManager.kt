package com.hyperswitchsdkreactnative.headless

typealias SessionCallback = (PaymentSessionHandler) -> Unit

object GetPaymentSessionCallBackManager {
    private var callback: SessionCallback? = null

    fun setCallback(newCallback: (PaymentSessionHandler) -> Unit) {
        callback = newCallback
    }

    fun getCallback(): SessionCallback? {
        return callback
    }

    fun executeCallback(data: PaymentSessionHandler) {
        val cb = callback
        callback = null
        cb?.invoke(data)
    }
}
