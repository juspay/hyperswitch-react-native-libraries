// HyperTypes.res

// Unified status type for all native layer responses
@genType
type responseStatus =
  | @as("succeeded") Succeeded
  | @as("failed") Failed
  | @as("cancelled") Cancelled
  | @as("error") Error

// Unified response type for all native layer API responses
@genType
type nativeResponse = {
  status: responseStatus,
  message: string,
  code?: string,
  data?: Js.Json.t,
}

// The hyperInstance type defines the interface for interacting with the Hyperswitch SDK
@genType
type hyperInstance = {
  // confirmPayment: Js.Json.t => promise<Js.Json.t>,
  initPaymentSession: (string) => promise<nativeResponse>,
  // completeUpdateIntent: string => promise<Js.Json.t>,
}

type paymentEvent = {
  eventName: string,
  payload?: JSON.t,
}

// UsePaymentSession response type
@genType
type paymentSession = {
  getCustomerDefaultSavedPaymentMethodData: unit => promise<nativeResponse>,
  getCustomerLastUsedPaymentMethodData: unit => promise<nativeResponse>,
  confirmWithCustomerDefaultPaymentMethod: string => promise<nativeResponse>,
  confirmWithCustomerLastUsedPaymentMethod: string => promise<nativeResponse>,
  confirmWithCustomerPaymentToken: string => promise<nativeResponse>,
  // presentPaymentSheet: (NativeHyperswitchSdk.presentPaymentSheetParams) => promise<NativeHyperswitchSdk.presentPaymentSheetResult>,

  presentPaymentSheet: (NativeHyperswitchSdk.presentPaymentSheetParams, option<paymentEvent => unit>) => promise<NativeHyperswitchSdk.presentPaymentSheetResult>,
  updateIntent: (~callback: unit => promise<string>) => promise<nativeResponse>
}


