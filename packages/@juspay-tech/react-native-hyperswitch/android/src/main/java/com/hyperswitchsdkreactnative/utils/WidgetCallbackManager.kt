package com.hyperswitchsdkreactnative.utils

import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReadableMap
import java.util.concurrent.ConcurrentHashMap

data class OnEventResult(
    val eventName: String,
    val payload: ReadableMap? = null
)

typealias EventCallback = (OnEventResult) -> Unit

object WidgetCallbackManager {
    private val paymentCallbacks = ConcurrentHashMap<String, Callback>()
    private val eventCallbacks = ConcurrentHashMap<String, EventCallback>()
    private val fragmentFlags = ConcurrentHashMap<String, Boolean>()
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

    fun setEventCallback(widgetId: String, callback: EventCallback) {
        eventCallbacks[widgetId] = callback
    }

    fun sendEvent(widgetId: String, eventName: String, payload: ReadableMap? = null) {
        eventCallbacks[widgetId]?.invoke(
            OnEventResult(eventName, payload)
        )
    }

    fun removeSession(sessionId: String) {
        paymentCallbacks.remove(sessionId)
        eventCallbacks.remove(sessionId)
        fragmentFlags.remove(sessionId)
    }

}
