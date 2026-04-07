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


// Widget controller type for useWidget hook
@genType
type widgetController = {
  confirmPayment: unit => promise<Js.Json.t>,
  presentPaymentSheet: NativeHyperswitchSdk.presentPaymentSheetParams => promise<NativeHyperswitchSdk.presentPaymentSheetResult>,
  isConfirmDisabled: bool,
  isLoading: bool,
  isReady: bool,
}

// Headless Payment Response Types
@genType
// TODO: Expand for all the native layer api responses.
type headlessResponse = {
  status: string,
  message: string,
  code?: string,
  data?: Js.Json.t,
}

// UsePaymentSession response type
@genType
type paymentSession = {
  getCustomerDefaultSavedPaymentMethodData: unit => promise<headlessResponse>,
  getCustomerLastUsedPaymentMethodData: unit => promise<headlessResponse>,
  confirmWithCustomerDefaultPaymentMethod: string => promise<headlessResponse>,
  confirmWithCustomerLastUsedPaymentMethod: string => promise<headlessResponse>,
  confirmWithCustomerPaymentToken: string => promise<headlessResponse>,
}
