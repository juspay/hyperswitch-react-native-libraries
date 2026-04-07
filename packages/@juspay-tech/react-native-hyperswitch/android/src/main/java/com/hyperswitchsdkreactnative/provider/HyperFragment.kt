package com.hyperswitchsdkreactnative.provider

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import com.facebook.react.ReactFragment
import com.facebook.react.ReactHost
import com.facebook.react.ReactNativeHost
import com.facebook.react.ReactRootView
import com.proyecto26.inappbrowser.ChromeTabsDismissedEvent
import com.proyecto26.inappbrowser.ChromeTabsManagerActivity
import io.hyperswitch.redirect.RedirectEvent
import org.greenrobot.eventbus.EventBus
import org.greenrobot.eventbus.Subscribe

internal class HyperFragment : ReactFragment() {

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    registerEventBus()
  }

  override fun onCreateView(
    inflater: LayoutInflater,
    container: ViewGroup?,
    savedInstanceState: Bundle?
  ): View? {
    val view = super.onCreateView(inflater, container, savedInstanceState)
    if (view is ReactRootView) {
      view.layoutParams = FrameLayout.LayoutParams(
        FrameLayout.LayoutParams.MATCH_PARENT,
        FrameLayout.LayoutParams.MATCH_PARENT
      )
    }
    return view
  }

  override fun getReactNativeHost(): ReactNativeHost {
    return ReactNativeController.getReactNativeHost()
  }

  override fun getReactHost(): ReactHost {
    return ReactNativeController.getReactHost()
  }

  override fun onDestroyView() {
    (view as? ReactRootView)?.unmountReactApplication()
    super.onDestroyView()
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
      val ARG_COMPONENT_NAME = "arg_component_name"
      val ARG_LAUNCH_OPTIONS = "arg_launch_options"
      val ARG_FABRIC_ENABLED = "arg_fabric_enabled"

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
