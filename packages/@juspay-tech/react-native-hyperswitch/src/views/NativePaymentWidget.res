type props = NativeModuleTypes.nativePaymentWidgetType


@module("./NativePaymentWidgetImpl.res.js")
external make: React.component<props> = "make"
