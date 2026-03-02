package com.hyperswitchsdkreactnative.react

import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import com.facebook.react.ReactFragment
import com.facebook.react.ReactHost
import com.facebook.react.ReactNativeHost
import com.facebook.react.ReactRootView
import com.facebook.react.common.annotations.UnstableReactNativeAPI
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

  override fun onCreateView(
    inflater: LayoutInflater,
    container: ViewGroup?,
    savedInstanceState: Bundle?
  ): View? {
    Log.i("HyperFragment", "onCreateView called")
    val view = super.onCreateView(inflater, container, savedInstanceState)
    if (view is ReactRootView) {
      view.layoutParams = FrameLayout.LayoutParams(
        FrameLayout.LayoutParams.MATCH_PARENT,
        FrameLayout.LayoutParams.MATCH_PARENT
      )
    }
    Log.i("HyperFragment", "View created: $view")
    return view
  }

  override fun getReactNativeHost(): ReactNativeHost {
    return ReactNativeController.getReactNativeHost()
  }

//   @OptIn(UnstableReactNativeAPI::class)
//   fun getReactHost(): ReactHost {
//     return ReactNativeController.getReactHost()
//   }

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
      var mFabricEnabled: Boolean = false

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
