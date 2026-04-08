package com.hyperswitchsdkreactnative.provider

import android.app.Activity
import android.content.Context
import android.graphics.Rect
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.webkit.WebSettings
import androidx.annotation.RequiresApi
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableType
import com.facebook.react.uimanager.PixelUtil
import com.hyperswitchsdkreactnative.provider.HyperProvider.Companion.readableArrayToArrayList
import org.json.JSONArray
import org.json.JSONObject
import kotlin.collections.iterator

class LaunchOptions(
    private val context: Context? = null,
    private val sdkVersion: String
) {

    private fun getHyperParams(): Bundle =
        Bundle().apply {
            putString("appId", context?.packageName)
            putString("country", context?.resources?.configuration?.locales?.get(0)?.country)
            putString("user-agent", getUserAgent(context))
            putDouble("launchTime", getCurrentTime())
            putString("sdkVersion", sdkVersion)
            putString("device_model", Build.MODEL)
            putString("os_type", "android")
            putString("os_version", Build.VERSION.RELEASE)
            putString("deviceBrand", Build.BRAND)
            val edgeInsets = getBottomInset(context)
            if(edgeInsets!=null) {
                putFloat("topInset", PixelUtil.toDIPFromPixel(edgeInsets.top))
                putFloat("leftInset", PixelUtil.toDIPFromPixel(edgeInsets.left))
                putFloat("rightInset", PixelUtil.toDIPFromPixel(edgeInsets.right))
                putFloat("bottomInset", PixelUtil.toDIPFromPixel(edgeInsets.bottom))
            }
        }

    fun getBundle(
        publishableKey: String? = null,
        clientSecret: String? = null,
        configuration: ReadableMap? = null,
        customBackendUrl: String? = null,
        customLogUrl: String? = null,
        customParams: ReadableMap? = null,
        type: String? = "payment",
        widgetId: String? = null,
        sdkAuthorization : String? = null,
        ): Bundle = Bundle().apply {
        putBundle("props", Bundle().apply {
          putString("type", type)
          putString("from", "rn")
          putString("publishableKey", publishableKey ?: "")
          putString("sdkAuthorization", sdkAuthorization?:"")
          putString("clientSecret", clientSecret ?: "")
          putBundle("configuration", readableMapToBundle(configuration))
          customBackendUrl?.let { url -> putString("customBackendUrl", url) }
          customLogUrl?.let { url -> putString("customLogUrl", url) }

          if (configuration?.hasKey("subscribedEvents") == true) {
            val subscribedEventsArray = configuration.getArray("subscribedEvents")
            if (subscribedEventsArray != null) {
              putSerializable("subscribedEvents", readableArrayToArrayList(subscribedEventsArray))
            }
          }
          customParams?.let { params ->
            putBundle(
              "customParams", readableMapToBundle(params)
            )
          }
          putBundle("hyperParams", getHyperParams())
          putString("widgetId", widgetId)
        })
    }

  fun readableMapToJSON(readableMap: ReadableMap?): JSONObject {
    val json = JSONObject()
    if (readableMap == null) return json

    val iterator = readableMap.keySetIterator()
    while (iterator.hasNextKey()) {
      val key = iterator.nextKey()
      val type = readableMap.getType(key)

      when (type) {
        ReadableType.Null -> json.put(key, JSONObject.NULL)
        ReadableType.Boolean -> json.put(key, readableMap.getBoolean(key))
        ReadableType.Number -> json.put(key, readableMap.getDouble(key))
        ReadableType.String -> json.put(key, readableMap.getString(key))
        ReadableType.Map -> json.put(key, readableMapToJSON(readableMap.getMap(key)))
        ReadableType.Array -> json.put(key, readableArrayToJSON(readableMap.getArray(key)))
      }
    }
    return json
  }

  fun readableArrayToJSON(readableArray: ReadableArray?): JSONArray {
    val json = JSONArray()
    if (readableArray == null) return json

    for (i in 0 until readableArray.size()) {
      val type = readableArray.getType(i)
      when (type) {
        ReadableType.Null -> json.put(JSONObject.NULL)
        ReadableType.Boolean -> json.put(readableArray.getBoolean(i))
        ReadableType.Number -> json.put(readableArray.getDouble(i))
        ReadableType.String -> json.put(readableArray.getString(i))
        ReadableType.Map -> json.put(readableMapToJSON(readableArray.getMap(i)))
        ReadableType.Array -> json.put(readableArrayToJSON(readableArray.getArray(i)))
      }
    }
    return json
  }

  fun readableMapToBundle(readableMap: ReadableMap?): Bundle {
    val bundle = Bundle()
    if (readableMap == null) return bundle

    val iterator = readableMap.keySetIterator()
    while (iterator.hasNextKey()) {
      val key = iterator.nextKey()
      val type = readableMap.getType(key)

      when (type) {
        ReadableType.Null -> bundle.putString(key, null)
        ReadableType.Boolean -> bundle.putBoolean(key, readableMap.getBoolean(key))
        ReadableType.Number -> {
          val value = readableMap.getDouble(key)
          if (value % 1 == 0.0) {
            bundle.putInt(key, value.toInt())
          } else {
            bundle.putDouble(key, value)
          }
        }

        ReadableType.String -> bundle.putString(key, readableMap.getString(key))
        ReadableType.Map -> bundle.putBundle(key, readableMapToBundle(readableMap.getMap(key)))
        ReadableType.Array -> {
          // Convert array to JSON string for simplicity
          bundle.putString(key, readableMap.getArray(key)?.toString())
        }
      }
    }
    return bundle
  }

  fun getBundleWithHyperParams(readableMap: Map<*, *>): Bundle = Bundle().apply {
        putBundle("props", toBundle(readableMap).apply {
            putBundle("hyperParams", getHyperParams())
        })
    }

    // Get user agent
    private fun getUserAgent(context: Context?): String? =
        try {
            if (context == null)
                System.getProperty("http.agent")
            else
                WebSettings.getDefaultUserAgent(context)
        } catch (_: RuntimeException) {
            System.getProperty("http.agent")
        }


    @RequiresApi(Build.VERSION_CODES.R)
    private fun getRootWindowInsetsCompatR(rootView: View): EdgeInsets? {
        val insets =
            rootView.rootWindowInsets?.getInsets(
                WindowInsets.Type.statusBars() or
                        WindowInsets.Type.displayCutout() or
                        WindowInsets.Type.navigationBars() or
                        WindowInsets.Type.captionBar())
                ?: return null
        return EdgeInsets(
            top = insets.top.toFloat(),
            right = insets.right.toFloat(),
            bottom = insets.bottom.toFloat(),
            left = insets.left.toFloat())
    }

    private fun getRootWindowInsetsCompatBase(rootView: View): EdgeInsets? {
        val visibleRect = Rect()
        rootView.getWindowVisibleDisplayFrame(visibleRect)
        return EdgeInsets(
            top = visibleRect.top.toFloat(),
            right = (rootView.width - visibleRect.right).toFloat(),
            bottom = (rootView.height - visibleRect.bottom).toFloat(),
            left = visibleRect.left.toFloat())
    }

    private fun getBottomInset(context: Context?): EdgeInsets? {
        val activity = context as? Activity
        if(activity != null) {
            val rootView = context.window.decorView
            return when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> getRootWindowInsetsCompatR(
                    rootView
                )
                else -> getRootWindowInsetsCompatBase(rootView)
            }
        } else {
            return null
        }
    }

    // Get current time in milliseconds
    private fun getCurrentTime(): Double = System.currentTimeMillis().toDouble()

    fun fromBundle(bundle: Bundle): Map<*, *> {
        val map = mutableMapOf<String, Any?>()
        for (key in bundle.keySet()) {
            val value = bundle[key]
            when {
                value == null -> {} //map[key] = null
                value.javaClass.isArray -> map[key] = value
                value is String -> map[key] = value
                value is Number -> map[key] = value as? Int ?: value.toDouble()
                value is Boolean -> map[key] = value
                value is Bundle -> map[key] = fromBundle(value)
                value is List<*> -> map[key] = value
                else -> throw IllegalArgumentException("Could not convert ${value.javaClass}")
            }
        }
        return map
    }

    fun toBundle(readableMap: Map<*, *>): Bundle {
        val bundle = Bundle()
        for ((key, value) in readableMap) {
            val keyString = key.toString()
            when (value) {
                null -> {} //bundle.putString(keyString, null)
                is Boolean -> bundle.putBoolean(keyString, value)
                is Number -> bundle.putDouble(keyString, value.toDouble())
                is String -> bundle.putString(keyString, value)
                is Map<*, *> -> bundle.putBundle(keyString, toBundle(value))
                is Array<*> -> bundle.putSerializable(keyString, value)
                else -> throw IllegalArgumentException("Could not convert object with key: $keyString.")
            }
        }
        return bundle
    }

    private fun toJson(bundle: Bundle): JSONObject {
        val json = JSONObject()
        for (key in bundle.keySet()) {
            when (val value = bundle[key]) {
                null -> {} //json.put(key, JSONObject.NULL)
                is Bundle -> json.put(key, toJson(value))
                is Boolean, is Int, is Float, is Long, is Double, is String -> json.put(key, value)
                is Array<*> -> json.put(key, JSONObject.wrap(value))
                is List<*> -> json.put(key, value)
                else -> throw IllegalArgumentException("Unsupported type for key: $key, $value")
            }
        }
        return json
    }

    private fun toJson(map: Map<*, *>): JSONObject {
        return JSONObject(map)
    }
}

data class EdgeInsets(val top: Float, val right: Float, val bottom: Float, val left: Float)
