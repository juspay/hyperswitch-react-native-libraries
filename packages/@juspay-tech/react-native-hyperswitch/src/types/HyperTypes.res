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
  initPaymentSession: string => promise<nativeResponse>,
  // completeUpdateIntent: string => promise<Js.Json.t>,
}

// Widget controller type for useWidget hook
@genType
type widgetController = {
  confirmPayment: string => promise<nativeResponse>,
  presentPaymentSheet: NativeHyperswitchSdk.presentPaymentSheetParams => promise<nativeResponse>,
  isConfirmDisabled: bool,
  isLoading: bool,
  isReady: bool,
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
