package com.juspaytech.reactnativehyperswitchpaypal

object PayPalPendingResult {
    @Volatile
    private var resultCallback: PayPalResultCallback? = null

    interface PayPalResultCallback {
        fun onSuccess(orderId: String, payerId: String)
        fun onCancelled()
        fun onFailure(errorMessage: String, errorCode: String?)
    }

    fun setCallback(callback: PayPalResultCallback?) {
        this.resultCallback = callback
    }

    fun notifySuccess(orderId: String, payerId: String) {
        resultCallback?.onSuccess(orderId, payerId)
        resultCallback = null
    }

    fun notifyCancelled() {
        resultCallback?.onCancelled()
        resultCallback = null
    }

    fun notifyFailure(errorMessage: String, errorCode: String?) {
        resultCallback?.onFailure(errorMessage, errorCode)
        resultCallback = null
    }
}
