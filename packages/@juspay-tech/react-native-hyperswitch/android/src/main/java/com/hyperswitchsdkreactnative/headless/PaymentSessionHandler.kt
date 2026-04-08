package com.hyperswitchsdkreactnative.headless

interface PaymentSessionHandler {
    fun getCustomerDefaultSavedPaymentMethodData(): Result<PaymentMethod>
    fun getCustomerLastUsedPaymentMethodData(): Result<PaymentMethod>
    fun getCustomerSavedPaymentMethodData(): Result<List<PaymentMethod>>
    fun confirmWithCustomerDefaultPaymentMethod(
        cvc: String? = null, resultHandler: (HeadlessPaymentResult) -> Unit
    )

    fun confirmWithCustomerLastUsedPaymentMethod(
        cvc: String? = null, resultHandler: (HeadlessPaymentResult) -> Unit
    )

    fun confirmWithCustomerPaymentToken(
        paymentToken: String, cvc: String? = null, resultHandler: (HeadlessPaymentResult) -> Unit
    )
}
