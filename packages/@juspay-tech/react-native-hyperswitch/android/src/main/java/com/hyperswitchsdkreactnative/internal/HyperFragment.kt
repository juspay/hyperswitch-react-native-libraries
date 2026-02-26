package com.hyperswitchsdkreactnative.internal

import android.os.Bundle
import com.facebook.react.HyperPackageList
import com.facebook.react.ReactFragment
import com.facebook.react.ReactHost
import com.facebook.react.ReactNativeHost
import com.facebook.react.ReactPackage
import com.facebook.react.bridge.JSBundleLoader
import com.facebook.react.bridge.ReactContext
import com.facebook.react.common.annotations.UnstableReactNativeAPI
import com.facebook.react.defaults.DefaultComponentsRegistry
import com.facebook.react.defaults.DefaultReactHostDelegate
import com.facebook.react.defaults.DefaultReactNativeHost
import com.facebook.react.defaults.DefaultTurboModuleManagerDelegate
import com.facebook.react.fabric.ComponentFactory
import com.facebook.react.runtime.ReactHostImpl
import com.facebook.react.runtime.cxxreactpackage.CxxReactPackage
import com.facebook.react.runtime.hermes.HermesInstance
import com.proyecto26.inappbrowser.ChromeTabsDismissedEvent
import com.proyecto26.inappbrowser.ChromeTabsManagerActivity
import io.hyperswitch.redirect.RedirectEvent
import org.greenrobot.eventbus.EventBus
import org.greenrobot.eventbus.Subscribe

class HyperFragment : ReactFragment() {

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    registerEventBus()
  }

  override fun getReactNativeHost(): ReactNativeHost {
    return object : DefaultReactNativeHost(requireActivity().application) {
      override fun getPackages(): List<ReactPackage> =
        HyperPackageList(this).packages

      override fun getJSMainModuleName(): String = "index"
      override fun getBundleAssetName(): String = "hyperswitch.bundle"
      override fun getUseDeveloperSupport(): Boolean = false
      override val isHermesEnabled: Boolean = true
      override val isNewArchEnabled: Boolean = true

      override fun getJSBundleFile(): String {
        return "assets://hyperswitch.bundle"
      }
    }
  }

   @OptIn(UnstableReactNativeAPI::class)
   override fun getReactHost(): ReactHost {
     val bundleLoader = JSBundleLoader.createAssetLoader(context, "assets://hyperswitch.bundle", true)

     val defaultTmmDelegateBuilder = DefaultTurboModuleManagerDelegate.Builder()
     val cxxReactPackageProviders: List<(ReactContext) -> CxxReactPackage> = emptyList()
     cxxReactPackageProviders.forEach { defaultTmmDelegateBuilder.addCxxReactPackage(it) }
     val defaultReactHostDelegate =
       DefaultReactHostDelegate(
         jsMainModulePath = "index",
         jsBundleLoader = bundleLoader,
         reactPackages = HyperPackageList(requireActivity().application).packages,
         jsRuntimeFactory = HermesInstance(),
         bindingsInstaller = null,
         turboModuleManagerDelegateBuilder = defaultTmmDelegateBuilder,
         exceptionHandler = {}
       )
     val componentFactory = ComponentFactory()
     DefaultComponentsRegistry.register(componentFactory)
     val reactHost =
       ReactHostImpl(
         requireActivity().application,
         defaultReactHostDelegate,
         componentFactory,
         true /* allowPackagerServerAccess */,
         false,
         )
     return reactHost
   }

    override fun onDestroy() {
      super.onDestroy()
      unRegisterEventBus()
    }

    private fun registerEventBus() {
      if (!EventBus.getDefault().isRegistered(this)) {
        EventBus.getDefault().register(this)
      }
    }

    fun unRegisterEventBus() {
      if (EventBus.getDefault().isRegistered(this)) {
        EventBus.getDefault().unregister(this)
      }
    }

    @Subscribe
    fun onEvent(event: RedirectEvent) {
      unRegisterEventBus()
      EventBus.getDefault().post(
        ChromeTabsDismissedEvent(
          event.message,
          event.resultType,
          event.isError
        )
      )
      startActivity(ChromeTabsManagerActivity.createDismissIntent(requireContext()))
    }

    class Builder {
      var mComponentName: String? = null
      var mLaunchOptions: Bundle? = null
      var mFabricEnabled: Boolean = true

      fun setComponentName(componentName: String?): Builder {
        mComponentName = componentName
        return this
      }

      fun setLaunchOptions(launchOptions: Bundle?): Builder {
        mLaunchOptions = launchOptions
        return this
      }

      fun build(): HyperFragment {
        val fragment = HyperFragment()
        val args = Bundle()
        args.putString(ARG_COMPONENT_NAME, mComponentName)
        args.putBundle(ARG_LAUNCH_OPTIONS, mLaunchOptions)
        args.putBoolean(ARG_FABRIC_ENABLED, mFabricEnabled)
        fragment.setArguments(args)
        return fragment
      }

      fun setFabricEnabled(fabricEnabled: Boolean): Builder {
        mFabricEnabled = fabricEnabled
        return this
      }
    }
  }
