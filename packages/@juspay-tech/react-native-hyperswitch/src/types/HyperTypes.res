// HyperTypes.res

// The hyperInstance type defines the interface for interacting with the Hyperswitch SDK
@genType
type hyperInstance = {
  confirmPayment: Js.Json.t => promise<Js.Json.t>,
  confirmCardPayment: (string, option<Js.Json.t>, option<Js.Json.t>) => promise<Js.Json.t>,
  retrievePaymentIntent: string => promise<Js.Json.t>,
  initPaymentSession: string => promise<Js.Json.t>,
  completeUpdateIntent: string => promise<Js.Json.t>,
}

// Context data type for HyperElements
@genType
type hyperElementsContextData = {
  hyperInstance: option<hyperInstance>,
  isInitialized: bool,
  error: option<string>,
}

// Widget controller type for useWidget hook
@genType
type widgetController = {
  confirmPayment: unit => promise<Js.Json.t>,
  presentPaymentSheet: NativeHyperswitchSdk.presentPaymentSheetParams => promise<NativeHyperswitchSdk.presentPaymentSheetResult>,
  isConfirmDisabled: bool,
  isLoading: bool,
  isReady: bool,
}
