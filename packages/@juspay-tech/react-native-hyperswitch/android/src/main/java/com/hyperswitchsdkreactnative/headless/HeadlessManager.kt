package com.hyperswitchsdkreactnative.headless

import android.app.Application
import android.os.Bundle
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.UiThreadUtil
import com.facebook.react.internal.featureflags.ReactNativeFeatureFlags
import com.facebook.react.ReactHost
import com.facebook.react.ReactInstanceEventListener
import com.facebook.react.ReactNativeHost
import com.facebook.react.jstasks.HeadlessJsTaskConfig
import com.facebook.react.jstasks.HeadlessJsTaskContext
import com.hyperswitchsdkreactnative.provider.ReactNativeController

/**
 * Manages starting HeadlessJsTask for headless payment methods.
 * 
 * Uses the RN wrapper's ReactNativeController to start a HeadlessJsTask
 * named "HyperHeadless" which runs the JS bundle's headless task logic.
 */
object HeadlessManager {

    private var headlessTaskId: Int? = null

    /**
     * Starts (or restarts) the HyperHeadless JS task with the given props.
     *
     * If ReactContext is already available, starts the task immediately.
     * Otherwise, waits for ReactContext initialization and then starts.
     *
     * @param props Bundle containing clientSecret, publishableKey, hyperParams, etc.
     */
    fun startHeadlessTask(props: Bundle, application: Application) {
        val reactNativeHost: ReactNativeHost?
        val reactHost: ReactHost?

        try {
            // Lazy-initialize ReactNativeController if not already done.
            if (!ReactNativeController.getIsInitialized()) {
                ReactNativeController.initialize(application)
            }
            reactNativeHost = ReactNativeController.getReactNativeHost()
            reactHost = ReactNativeController.getReactHost()
        } catch (e: Exception) {
            throw IllegalStateException(
                "HyperSDK not initialized. Please call initialise() first.", e
            )
        }

        UiThreadUtil.runOnUiThread {
            val reactContext: ReactContext? = try {
                if (ReactNativeFeatureFlags.enableBridgelessArchitecture()) {
                    reactHost.currentReactContext
                } else {
                    reactNativeHost.reactInstanceManager?.currentReactContext
                }
            } catch (e: Exception) {
                null
            }

            if (reactContext != null) {
                invokeStartTask(reactContext, props)
            } else {
                // ReactContext not yet ready, wait for initialization
                if (ReactNativeFeatureFlags.enableBridgelessArchitecture()) {
                    reactHost.addReactInstanceEventListener(
                        object : ReactInstanceEventListener {
                            override fun onReactContextInitialized(context: ReactContext) {
                                invokeStartTask(context, props)
                                reactHost.removeReactInstanceEventListener(this)
                            }
                        }
                    )
                    reactHost.start()
                } else {
                    val reactInstanceManager = reactNativeHost.reactInstanceManager
                    reactInstanceManager?.addReactInstanceEventListener(
                        object : ReactInstanceEventListener {
                            override fun onReactContextInitialized(context: ReactContext) {
                                invokeStartTask(context, props)
                                reactInstanceManager.removeReactInstanceEventListener(this)
                            }
                        }
                    )
                    reactInstanceManager?.createReactContextInBackground()
                }
            }
        }
    }

    private fun invokeStartTask(reactContext: ReactContext, props: Bundle) {
        val taskConfig = HeadlessJsTaskConfig(
            "HyperHeadless",
            Arguments.fromBundle(props),
            5000,  // timeout ms
            true,  // allowed in foreground
            null
        )

        val headlessJsTaskContext = HeadlessJsTaskContext.getInstance(reactContext)
        UiThreadUtil.runOnUiThread {
            // Finish any previously running headless task
            headlessTaskId?.let {
                try {
                    headlessJsTaskContext.finishTask(it)
                } catch (_: Exception) {}
            }
            headlessTaskId = headlessJsTaskContext.startTask(taskConfig)
        }
    }
}
