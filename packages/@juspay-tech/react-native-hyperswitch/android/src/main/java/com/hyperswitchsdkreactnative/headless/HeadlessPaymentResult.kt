package com.hyperswitchsdkreactnative.headless

import android.content.Intent
import android.os.Bundle
import android.os.Parcelable
import kotlinx.parcelize.Parcelize

/**
 * Result to be passed to the callback of [PaymentLauncher]
 */
sealed class HeadlessPaymentResult : Parcelable {
    @Parcelize
    class Completed(val data: String) : HeadlessPaymentResult()

    @Parcelize
    class Failed(val throwable: Throwable) : HeadlessPaymentResult()

    @Parcelize
    class Canceled(val data: String) : HeadlessPaymentResult()

    @JvmSynthetic
    fun toBundle() = Bundle().apply {
        putParcelable(EXTRA, this)
    }

    internal companion object {
        private const val EXTRA = "extra_args"

        @JvmSynthetic
        fun fromIntent(intent: Intent?): HeadlessPaymentResult {
            return intent?.getParcelableExtra(EXTRA)
                ?: Failed(IllegalStateException("Failed to get PaymentResult from Intent"))
        }
    }
}
