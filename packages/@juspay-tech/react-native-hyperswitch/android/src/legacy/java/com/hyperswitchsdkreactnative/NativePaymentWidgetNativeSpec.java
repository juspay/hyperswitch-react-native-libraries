package com.hyperswitchsdkreactnative;

import com.facebook.proguard.annotations.DoNotStrip;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.turbomodule.core.interfaces.TurboModule;

import javax.annotation.Nonnull;

public abstract class NativePaymentWidgetNativeSpec extends ReactContextBaseJavaModule implements TurboModule {
  public static final String NAME = "NativePaymentWidget";

  public NativePaymentWidgetNativeSpec(ReactApplicationContext reactContext) {
    super(reactContext);
  }

  @Override
  public @Nonnull String getName() {
    return NAME;
  }

  @ReactMethod
  @DoNotStrip
  public abstract void confirmPayment(Integer reactTag, Callback callback);
}
