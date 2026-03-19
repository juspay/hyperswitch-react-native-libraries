package com.hyperswitchsdkreactnative.utils

import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.Promise
import java.util.concurrent.ConcurrentHashMap

data class OnEventResult(
    val eventName: String,
    val payload: String? = null
)

typealias EventCallback = (OnEventResult) -> Unit

object WidgetCallbackManager {
    private val paymentCallbacks = ConcurrentHashMap<String, Callback>()
    private val eventCallbacks = ConcurrentHashMap<String, EventCallback>()
    private val fragmentFlags = ConcurrentHashMap<String, Boolean>()
    private val confirmPromises = ConcurrentHashMap<String, Promise>()

    fun setCallback(
        callback: Callback,
        isFragment: Boolean = true,
        sessionId: String = ""
    ) {
        paymentCallbacks[sessionId] = callback
        fragmentFlags[sessionId] = isFragment
    }

    fun getCallback(sessionId: String): Callback? {
        return paymentCallbacks.get(sessionId)
    }

    fun executeCallback(data: String, sessionId: String = ""): Boolean {
        val callback = getCallback(sessionId) ?: return false
        callback.invoke(data)
        removeSession(sessionId)
        return fragmentFlags[sessionId] ?: true
    }

    fun setEventCallback(sessionId: String, callback: EventCallback) {
        eventCallbacks[sessionId] = callback
    }

    fun sendEvent(sessionId: String, eventName: String, payload: String? = null) {
        eventCallbacks[sessionId]?.invoke(
            OnEventResult(eventName, payload)
        )
    }

    fun removeSession(sessionId: String) {
        paymentCallbacks.remove(sessionId)
        eventCallbacks.remove(sessionId)
        fragmentFlags.remove(sessionId)
        confirmPromises.remove(sessionId)
    }

    fun setConfirmPromise(widgetId: String, promise: Promise) {
        confirmPromises[widgetId] = promise
    }

    fun resolveConfirmPromise(widgetId: String, result: String) {
        confirmPromises[widgetId]?.let {
            it.resolve(result)
            confirmPromises.remove(widgetId)
        }
    }

    fun rejectConfirmPromise(widgetId: String, error: String) {
        confirmPromises[widgetId]?.let {
            it.reject("CONFIRM_PAYMENT_ERROR", error)
            confirmPromises.remove(widgetId)
        }
    }

}
