
type initialise = (
  ~publishableKey: string,
  ~customBackendUrl: option<string>,
  ~customLogUrl: option<string>,
  ~customParams: option<Js.Json.t>,
) => promise<unit>


// New method types for the updated API
type confirmPayment = Js.Json.t => promise<string>
type confirmCardPayment = Js.Json.t => promise<string>
type retrievePaymentIntent = Js.Json.t => promise<string>
type completeUpdateIntent = Js.Json.t => promise<string>

type initPaymentSession = (~paymentIntentClientSecret: string) => promise<string>


@genType
type initPaymentSessionParams = {paymentIntentClientSecret?: string, sdkAuthorisation?: string}

@genType
type initPaymentSessionResult = {error?: string}

@genType
type presentPaymentSheetParams = PaymentSheetConfiguration.options

type status =
  | @as("succeeded") Completed
  | @as("cancelled") Canceled
  | @as("Failed") Failed

@genType
type paymentResult = {
  status: string,
  message: string,
  error?: string,
  @as("type") type_?: string,
}

@genType
type error = {
  code?: string,
  message?: string
}

@genType
type presentPaymentSheetResult = {
  error?: error,
  paymentResult?: paymentResult
}

@genType
type presentPaymentSheet = presentPaymentSheetParams => promise<string>

// Headless Payment Method types
type getCustomerSavedPaymentMethods = unit => promise<string>
type getCustomerDefaultSavedPaymentMethodData = unit => promise<string>
type getCustomerLastUsedPaymentMethodData = unit => promise<string>
type confirmWithCustomerDefaultPaymentMethod = unit => promise<string>
type confirmWithCustomerLastUsedPaymentMethod = unit => promise<string>

type nativeHyperswitchSdk = {
  initialise: initialise,
  initPaymentSession: initPaymentSession,
  presentPaymentSheet: presentPaymentSheet,
  // New methods
  confirmPayment: confirmPayment,
  confirmCardPayment: confirmCardPayment,
  retrievePaymentIntent: retrievePaymentIntent,
  completeUpdateIntent: completeUpdateIntent,
  // Headless Payment Methods
  getCustomerSavedPaymentMethods: getCustomerSavedPaymentMethods,
  getCustomerDefaultSavedPaymentMethodData: getCustomerDefaultSavedPaymentMethodData,
  getCustomerLastUsedPaymentMethodData: getCustomerLastUsedPaymentMethodData,
  confirmWithCustomerDefaultPaymentMethod: confirmWithCustomerDefaultPaymentMethod,
  confirmWithCustomerLastUsedPaymentMethod: confirmWithCustomerLastUsedPaymentMethod,
}

@module("../specs/NativeHyperswitchSdkReactNative")
external nativeHyperswitchSdk: nativeHyperswitchSdk = "default"
