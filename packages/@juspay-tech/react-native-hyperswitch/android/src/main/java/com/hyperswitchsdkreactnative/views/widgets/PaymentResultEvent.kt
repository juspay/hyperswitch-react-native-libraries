package com.hyperswitchsdkreactnative.views.widgets

import com.facebook.react.bridge.WritableNativeMap
import com.facebook.react.uimanager.events.Event

class PaymentResultEvent(
    surfaceId: Int,
    viewTag: Int,
    private val eventName: String,
    private val payload: WritableNativeMap,
) : Event<PaymentResultEvent>(surfaceId, viewTag) {

    override fun getEventName(): String = eventName

    override fun getCoalescingKey(): Short = 0

    override fun getEventData(): WritableNativeMap = payload
}
