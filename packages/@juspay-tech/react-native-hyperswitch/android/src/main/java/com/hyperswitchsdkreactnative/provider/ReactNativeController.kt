package com.hyperswitchsdkreactnative.provider

import android.app.Application
import android.content.Context
import com.facebook.react.HyperPackageList
import com.facebook.react.ReactHost
import com.facebook.react.ReactNativeHost
import com.facebook.react.ReactPackage
import com.facebook.react.bridge.JSBundleLoader
import com.facebook.react.bridge.ReactContext
import com.facebook.react.common.annotations.UnstableReactNativeAPI
import com.facebook.react.defaults.DefaultComponentsRegistry
import com.facebook.react.defaults.DefaultReactHost
import com.facebook.react.defaults.DefaultReactHostDelegate
import com.facebook.react.defaults.DefaultReactNativeHost
import com.facebook.react.defaults.DefaultTurboModuleManagerDelegate
import com.facebook.react.fabric.ComponentFactory
import com.facebook.react.runtime.ReactHostImpl
import com.facebook.react.runtime.cxxreactpackage.CxxReactPackage
import com.facebook.react.runtime.hermes.HermesInstance
import com.hyperswitchsdkreactnative.BuildConfig
import com.hyperswitchsdkreactnative.R
import io.hyperswitch.logs.CrashHandler
import io.hyperswitch.logs.EventName
import io.hyperswitch.logs.HSLog
import io.hyperswitch.logs.HyperLogManager
import io.hyperswitch.logs.LogCategory
import io.hyperswitch.logs.LogUtils
import io.hyperswitch.logs.SDKEnvironment

/**
 * ReactNativeController
 *
 * Entry point for initializing and accessing the Hyperswitch React Native runtime.
 * This object is responsible for:
 * - Initializing React Native (Old & New Architecture)
 * - Loading JS bundles (OTA or bundled assets)
 * - Managing ReactHost / ReactNativeHost lifecycle
 * - Setting up crash handling and native dependencies
 *
 * This SDK is designed to be initialized once per application lifecycle.
 */
object ReactNativeController {

  private var reactNativeHost: ReactNativeHost? = null
  private var reactHost: ReactHost? = null

  @Volatile
  private var isInitialized = false

  /**
   * Resolves the JavaScript bundle path using Hyper Airborne OTA if available.
   *
   * Behavior:
   * - Determines SDK environment using the publishable key
   * - Reads OTA endpoint from resources based on environment
   * - Dynamically loads AirborneOTA via reflection (optional dependency)
   * - Fetches the OTA-downloaded bundle path
   * - Falls back to bundled assets if OTA is disabled, unavailable, or fails
   *
   * @param application Application context
   * @return Path to the JS bundle (OTA or bundled asset)
   */
  private fun getBundleFromAirborne(application: Application): String {
    try {
      val environment =
        LogUtils.getEnvironment(HyperProvider.publishableKey())
      val airborneUrl = application.getString(
        if (environment == SDKEnvironment.SANDBOX)
          R.string.hyperOTASandBoxEndPoint
        else
          R.string.hyperOTAEndPoint
      )

      // Ensure OTA endpoint is valid
      if (airborneUrl != "hyperOTA_END_POINT_") {
        val airborneClass =
          Class.forName("io.hyperswitch.airborne.AirborneOTA")

        val constructor = airborneClass.getConstructor(
          Context::class.java,
          String::class.java,
          String::class.java
        )

        val instance = constructor.newInstance(
          application.applicationContext,
          BuildConfig.VERSION_NAME,
          airborneUrl
        )

        val getBundlePath =
          airborneClass.getMethod("getBundlePath")
        return getBundlePath.invoke(instance) as String
      }
    } catch (_: Exception) {
    }
    return "assets://hyperswitch.bundle"
  }

  /**
   * Creates and configures the ReactNativeHost instance.
   *
   * Responsibilities:
   * - Registers required React Native packages
   * - Enables Hermes and New Architecture flags
   * - Resolves JS bundle source (OTA or bundled)
   *
   * @param application Application context
   * @return Configured ReactNativeHost instance
   */
  private fun createReactNativeHost(
    application: Application,
  ): ReactNativeHost {
    return object : DefaultReactNativeHost(application) {
      override fun getPackages(): List<ReactPackage> {
        return HyperPackageList(this).packages
      }

      override fun getJSMainModuleName(): String = "index"
      override fun getUseDeveloperSupport(): Boolean = false //BuildConfig.DEBUG
      override val isNewArchEnabled: Boolean =
        BuildConfig.IS_NEW_ARCHITECTURE_ENABLED
      override val isHermesEnabled: Boolean =
        BuildConfig.IS_HERMES_ENABLED

      override fun getJSBundleFile(): String =
        getBundleFromAirborne(application)

    }
  }

  /**
   * Returns whether the SDK has already been initialized.
   *
   * @return true if initialized, false otherwise
   */
  fun getIsInitialized(): Boolean {
    return isInitialized
  }

  /**
   * Returns the initialized ReactNativeHost instance.
   *
   * @throws IllegalStateException if SDK is not initialized
   * @return ReactNativeHost
   */
  fun getReactNativeHost(): ReactNativeHost {
    return checkNotNull(reactNativeHost) {
      "ReactNative not initialized. Call ReactNativeController.initialize()"
    }
  }

  /**
   * Returns the initialized ReactHost instance.
   *
   * @throws IllegalStateException if SDK is not initialized
   * @return ReactHost
   */
  fun getReactHost(): ReactHost {
    return checkNotNull(reactHost) {
      "ReactNative not initialized. Call ReactNativeController.initialize()"
    }
  }

  @OptIn(UnstableReactNativeAPI::class)
  fun createReactHost(application: Application): ReactHost {

    val bundleLoader =
      JSBundleLoader.createAssetLoader(application, "assets://hyperswitch.bundle", true)

    val defaultTmmDelegateBuilder = DefaultTurboModuleManagerDelegate.Builder()
    val cxxReactPackageProviders: List<(ReactContext) -> CxxReactPackage> = emptyList()
    cxxReactPackageProviders.forEach { defaultTmmDelegateBuilder.addCxxReactPackage(it) }
    val defaultReactHostDelegate =
      DefaultReactHostDelegate(
        jsMainModulePath = "index",
        jsBundleLoader = bundleLoader,
        reactPackages = HyperPackageList(application).packages,
        jsRuntimeFactory = HermesInstance(),
        bindingsInstaller = null,
        turboModuleManagerDelegateBuilder = defaultTmmDelegateBuilder,
        exceptionHandler = {}
      )
    val componentFactory = ComponentFactory()
    DefaultComponentsRegistry.register(componentFactory)

    return ReactHostImpl(
      application.applicationContext,
      defaultReactHostDelegate,
      componentFactory,
      false, /* allowPackagerServerAccess */
      false
    )
  }

  /**
   * Initializes the ReactNativeController.
   *
   * This method:
   * - Ensures single initialization (thread-safe)
   * - Registers a global crash handler
   * - Initializes SoLoader
   * - Loads New Architecture entry point if enabled
   * - Creates ReactNativeHost and ReactHost instances
   * @param application Application instance
   */
  fun initialize(application: Application) {
    try {
      synchronized(this) {
        if (isInitialized) return

        Thread.setDefaultUncaughtExceptionHandler(
          CrashHandler(application, BuildConfig.VERSION_NAME)
        )

        reactNativeHost =
          createReactNativeHost(application)

        reactHost = createReactHost(application)

        isInitialized = true
      }
    } catch (e: Exception) {
      HyperLogManager.addLog(
        HSLog.LogBuilder()
          .value("Failed to initialize Hyperswitch SDK: ${e.message}")
          .category(LogCategory.API)
          .logType("error")
          .eventName(EventName.CRASH_EVENT)
          .build()
      )
    }
  }
}
