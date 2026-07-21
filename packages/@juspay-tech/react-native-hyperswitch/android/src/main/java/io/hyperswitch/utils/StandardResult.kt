package io.hyperswitch.utils

import org.json.JSONObject
sealed class StandardResult {

  abstract val code: String?
  abstract val message: String?
  abstract val status: String
  abstract val error: Throwable?

  data class Success(
    override val code: String? = null,
    override val message: String? = null
  ) : StandardResult() {
    override val status: String = "success"
    override val error: Throwable? = null
  }

  data class Failed(
    override val code: String? = null,
    override val message: String? = null,
    override val error: Throwable? = null
  ) : StandardResult() {
    override val status: String = "failed"
  }

  data class Cancelled(
    override val code: String? = null,
    override val message: String? = "Payment cancelled"
  ) : StandardResult() {
    override val status: String = "cancelled"
    override val error: Throwable? = null
  }

  fun toJSON(): JSONObject {
    return JSONObject().apply {
      put("code", code ?: JSONObject.NULL)
      put("message", message ?: error?.message ?: JSONObject.NULL)
      put("status", status)
      put("error", error?.message ?: JSONObject.NULL)
    }
  }

  fun toJSONString(): String = toJSON().toString()
}
