package io.hyperswitch.paymentsheet

import android.content.Intent
import android.os.Bundle
import android.os.Parcelable
import kotlinx.parcelize.Parcelize
import org.json.JSONObject

/**
 * Result to be passed to the callback of [PaymentLauncher]
 */
sealed class PaymentResult : Parcelable {
  @Parcelize
  class Completed(val data: String) : PaymentResult()

  @Parcelize
  class Failed(val throwable: Throwable) : PaymentResult()

  @Parcelize
  class Canceled(val data: String) : PaymentResult()

  @JvmSynthetic
  fun toBundle() = Bundle().apply {
    putParcelable(EXTRA, this@PaymentResult)
  }

  @JvmSynthetic
  fun toJSONString(): String {
    return when (this) {
      is Completed -> {
        JSONObject()
          .put("status", "completed")
          .put("data", data)
          .toString()
      }

      is Canceled -> {
        JSONObject()
          .put("status", "canceled")
          .put("data", data)
          .toString()
      }

      is Failed -> {
        JSONObject()
          .put("status", "failed")
          .put("error", throwable.message)
          .put("type", throwable::class.java.name)
          .toString()
      }
    }
  }

  internal companion object {
    private const val EXTRA = "extra_args"

    @JvmSynthetic
    fun fromIntent(intent: Intent?): PaymentResult {
      return intent?.getParcelableExtra(EXTRA)
        ?: Failed(IllegalStateException("Failed to get PaymentResult from Intent"))
    }
  }
}
