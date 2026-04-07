package com.hyperswitchsdkreactnative.utils

import com.facebook.react.bridge.Callback
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

data class OnEventResult(
    val eventName: String,
    val payload: String? = null
)

typealias EventCallback = (OnEventResult) -> Unit

object CallbackManager {
    private val paymentCallbacks = ConcurrentHashMap<String, Callback>()
    private val eventCallbacks = ConcurrentHashMap<String, EventCallback>()
    private val fragmentFlags = ConcurrentHashMap<String, Boolean>()
    fun setCallback(
        callback: Callback,
        isFragment: Boolean = true,
        requestId: String = ""
    ) {
        paymentCallbacks[requestId] = callback
        fragmentFlags[requestId] = isFragment
    }

    fun getCallback(requestId: String): Callback? {
        return paymentCallbacks.get(requestId)
    }

    fun executeCallback(data: String, requestId: String = ""): Boolean {
        val callback = getCallback(requestId) ?: return false
        callback.invoke(data)
        removeSession(requestId)
        return fragmentFlags[requestId] ?: true
    }

    fun setEventCallback(requestId: String, callback: EventCallback) {
        eventCallbacks[requestId] = callback
    }

    fun sendEvent(requestId: String, eventName: String, payload: String? = null) {
        eventCallbacks[requestId]?.invoke(
            OnEventResult(eventName, payload)
        )
    }

    fun removeSession(requestId: String) {
        paymentCallbacks.remove(requestId)
        eventCallbacks.remove(requestId)
        fragmentFlags.remove(requestId)
    }

}
