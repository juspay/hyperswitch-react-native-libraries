
type initialise = (
  ~publishableKey: string,
  ~customBackendUrl: option<string>,
  ~customLogUrl: option<string>,
  ~customParams: option<Js.Json.t>,
) => promise<unit>



// type completeUpdateIntent = Js.Json.t => promise<string>

type initPaymentSession = (~paymentIntentClientSecret: string) => promise<string>


@genType
type initPaymentSessionParams = {paymentIntentClientSecret?: string, sdkAuthorisation?: string}

@genType
type initPaymentSessionResult = {error?: string}

@genType
type presentPaymentSheetParams = PaymentSheetConfiguration.options

@genType
type presentPaymentSheet = presentPaymentSheetParams => promise<string>

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

// Card details for saved payment methods
@genType
type cardDetails = {
  expiry_year: string,
  card_issuer: string,
  expiry_month: string,
  nick_name: string,
  last4_digits: string,
  card_holder_name: string,
  card_network: string,
  card_isin: string,
  scheme: string,
  issuer_country: string,
  card_type: string,
  saved_to_locker: bool,
}

// Saved payment method data structure
@genType
type savedPaymentMethod = {
  card?: cardDetails,
  requires_cvv: bool,
  payment_method_str: string,
  payment_method_type: string,
  payment_experience: array<string>,
  default_payment_method_set: bool,
  recurring_enabled: bool,
  payment_method_issuer: string,
  last_used_at: string,
  installment_payment_enabled: bool,
  payment_method_id: string,
  customer_id: string,
  payment_token: string,
  created: string,
}

// Headless Payment Method types
type getCustomerSavedPaymentMethods = unit => promise<string>
type getCustomerDefaultSavedPaymentMethodData = unit => promise<string>
type getCustomerLastUsedPaymentMethodData = unit => promise<string>
type confirmWithCustomerDefaultPaymentMethod = string => promise<string>
type confirmWithCustomerLastUsedPaymentMethod = string => promise<string>
type confirmWithCustomerPaymentToken = string => promise<string>


type confirmPayment = (int, paymentResult  => unit) => unit

type nativeHyperswitchSdk = {
  initialise: initialise,
  initPaymentSession: initPaymentSession,
  presentPaymentSheet: presentPaymentSheet,
  // New methods
  // confirmPayment: confirmPayment,
  // completeUpdateIntent: completeUpdateIntent,
  // Headless Payment Methods
  getCustomerSavedPaymentMethods: getCustomerSavedPaymentMethods,
  getCustomerDefaultSavedPaymentMethodData: getCustomerDefaultSavedPaymentMethodData,
  getCustomerLastUsedPaymentMethodData: getCustomerLastUsedPaymentMethodData,
  confirmWithCustomerDefaultPaymentMethod: confirmWithCustomerDefaultPaymentMethod,
  confirmWithCustomerLastUsedPaymentMethod: confirmWithCustomerLastUsedPaymentMethod,
  confirmWithCustomerPaymentToken: confirmWithCustomerPaymentToken,
}

@module("../specs/NativeHyperswitchSdkReactNative")
external nativeHyperswitchSdk: nativeHyperswitchSdk = "default"



// Nativemodule with NativePaymentWidget 

type nativePaymentWidget = {
  // New methods
  confirmPayment: confirmPayment,
}


let nativePaymentWidgetDict =
  Dict.get(ReactNative.NativeModules.nativeModules, "NativePaymentWidget")
  ->Option.flatMap(JSON.Decode.object)
  ->Option.getOr(Dict.make())

let getFunctionFromModule = (dict: Dict.t<'a>, key: string, default) => {
  switch dict->Dict.get(key) {
  | Some(fn) => Obj.magic(fn)
  | None => default
  }
}

let nativePaymentWidget = {
  confirmPayment: getFunctionFromModule(nativePaymentWidgetDict, "confirmPayment", (_, _) => ()),
}

let confirmPayment = (viewId: int, callback: paymentResult => unit) => {
  nativePaymentWidget.confirmPayment(viewId, (result: paymentResult) => {
    callback(result)
  })
}