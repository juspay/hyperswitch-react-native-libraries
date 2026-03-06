open NewArchUtils

let make: React.component<NativeModuleTypes.nativePaymentWidgetType> = if isFabricEnabled() {
  let turboGooglePayButton = %raw(
      "require('../specs/PaymentWidgetNativeComponent.ts')"
    )
    turboGooglePayButton["default"]
} else {
  ReactNative.NativeModules.requireNativeComponent("NativePaymentWidget")
}
