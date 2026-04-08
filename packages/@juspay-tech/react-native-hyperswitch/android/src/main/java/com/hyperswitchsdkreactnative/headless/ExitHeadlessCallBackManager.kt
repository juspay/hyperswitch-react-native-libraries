package com.hyperswitchsdkreactnative.headless

import org.json.JSONObject

typealias ExitCallback = (HeadlessPaymentResult) -> Unit

object ExitHeadlessCallBackManager {
    private var callback: ExitCallback? = null

    fun setCallback(newCallback: (HeadlessPaymentResult) -> Unit) {
        callback = newCallback
    }

    fun getCallback(): ExitCallback? {
        return callback
    }

    fun executeCallback(data: String) {
        val message = JSONObject(data)
        val result = when (val status = message.getString("status")) {
            "cancelled" -> HeadlessPaymentResult.Canceled(status)
            "failed", "requires_payment_method" -> {
                val throwable = Throwable(message.getString("message"))
                throwable.initCause(Throwable(message.getString("code")))
                HeadlessPaymentResult.Failed(throwable)
            }

            else -> HeadlessPaymentResult.Completed(status ?: "default")
        }
        val cb = callback
        callback = null
        cb?.invoke(result)

    }
}
