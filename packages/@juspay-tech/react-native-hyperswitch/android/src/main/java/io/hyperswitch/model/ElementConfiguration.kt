package io.hyperswitch.model

import io.hyperswitch.utils.StandardResult

//sealed class ElementsUpdateResult {
//
//    /** All elements updated successfully. */
//    object Success : ElementsUpdateResult()
//
//    /**
//     * Session token fetch failed before any element was updated.
//     * No element was touched — safe to retry the entire call.
//     */
//    data class TotalFailure(
//        val cause: Throwable
//    ) : ElementsUpdateResult()
//
//    /**
//     * Token fetch succeeded but one or more elements failed to update.
//     * [succeeded] elements are live; [failed] elements can be selectively retried.
//     */
//    data class PartialFailure(
//        val succeeded: List<HyperswitchBoundElement>,
//        val failed: Map<HyperswitchBoundElement, Throwable>
//    ) : ElementsUpdateResult() {
//        val canRetry: Boolean get() = failed.isNotEmpty()
//    }
//}

sealed class ElementUpdateIntentResult {
  object Success : ElementUpdateIntentResult()
  object Cancelled : ElementUpdateIntentResult()
  data class Failure(val cause: Throwable) : ElementUpdateIntentResult()

  fun ElementUpdateIntentResult.toStandardResult(): StandardResult {
    return when (this) {
      ElementUpdateIntentResult.Success -> {
        StandardResult.Success(
          message = "Element update intent completed successfully"
        )
      }

      ElementUpdateIntentResult.Cancelled -> {
        StandardResult.Cancelled(
          message = "Element update intent was cancelled"
        )
      }

      is ElementUpdateIntentResult.Failure -> {
        StandardResult.Failed(
          code = "element_update_failed",
          message = cause.message ?: "Element update intent failed",
          error = cause
        )
      }
    }
  }
}
