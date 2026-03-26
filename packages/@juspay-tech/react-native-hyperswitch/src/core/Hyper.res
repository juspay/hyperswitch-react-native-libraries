// Hyper.res
// Main entry point for the Hyperswitch SDK
// Provides Hyper.init() function to create a hyper instance with configuration

open NativeHyperswitchSdk


type globalConfig = {
  publishableKey: string,
  profileId: string,
  customBackendUrl?: string,
  customLogUrl?: string,
  customParams?: Js.Json.t,
}

// Global config storage (set by Hyper.init, used by HyperElements)
let globalConfigRef: ref<option<globalConfig>> = ref(None)

let getGlobalConfig = () => globalConfigRef.contents

let setGlobalConfig = (
  ~publishableKey: string,
  ~profileId: string,
  ~customBackendUrl: option<string>=?,
  ~customLogUrl: option<string>=?,
  ~customParams: option<Js.Json.t>=?,
) => {
  globalConfigRef := Some({
    publishableKey: publishableKey,
    profileId: profileId,
    ?customBackendUrl,
    ?customLogUrl,
    ?customParams,
  })
}

// Parse payment result from native SDK
let parsePaymentResult = (result: 'a): Js.Json.t => {
  try {
    switch Js.typeof(result) {
    | "string" => Js.Json.parseExn(result)
    | _ => result->Obj.magic
    }
  } catch {
  | _ =>
    let errorObj = Dict.make()
    errorObj->Dict.set("status", "failed"->Js.Json.string)
    errorObj->Dict.set("message", "Failed to parse payment result"->Js.Json.string)
    errorObj->Js.Json.object_
  }
}

// Create a hyper instance with the given config
let createHyperInstance = (): HyperTypes.hyperInstance => {
  confirmPayment: (paymentParams: Js.Json.t) => {
    let paramsDict = Js.Dict.empty()
    paramsDict->Js.Dict.set("paymentParams", paymentParams)
    let params = paramsDict->Js.Json.object_
    nativeHyperswitchSdk.confirmPayment(params)->Promise.thenResolve(parsePaymentResult)
  },

  confirmCardPayment: (
    clientSecret: string,
    paymentMethodData: option<Js.Json.t>,
    paymentIntentParams: option<Js.Json.t>
  ) => {
    let paramsDict = Js.Dict.empty()
    paramsDict->Js.Dict.set("clientSecret", clientSecret->Js.Json.string)
    paramsDict->Js.Dict.set("paymentMethodData", paymentMethodData->Option.getOr(Js.Json.null))
    paramsDict->Js.Dict.set("paymentIntentParams", paymentIntentParams->Option.getOr(Js.Json.null))
    let params = paramsDict->Js.Json.object_
    nativeHyperswitchSdk.confirmCardPayment(params)->Promise.thenResolve(parsePaymentResult)
  },

  retrievePaymentIntent: (clientSecret: string) => {
    let paramsDict = Js.Dict.empty()
    paramsDict->Js.Dict.set("clientSecret", clientSecret->Js.Json.string)
    let params = paramsDict->Js.Json.object_
    nativeHyperswitchSdk.retrievePaymentIntent(params)->Promise.thenResolve(parsePaymentResult)
  },

  initPaymentSession: (sessionParams: string) => {
    nativeHyperswitchSdk.initPaymentSession(~paymentIntentClientSecret=sessionParams)->Promise.thenResolve(parsePaymentResult)
  },

  completeUpdateIntent: (clientSecret: string) => {
    let paramsDict = Js.Dict.empty()
    paramsDict->Js.Dict.set("clientSecret", clientSecret->Js.Json.string)
    let params = paramsDict->Js.Json.object_
    nativeHyperswitchSdk.completeUpdateIntent(params)->Promise.thenResolve(parsePaymentResult)
  },
}

// Helper to get string from JSON config
let getStringFromConfig = (config: option<Js.Json.t>, key: string): option<string> => {
  switch config {
  | Some(cfg) => {
      cfg
      ->Js.Json.decodeObject
      ->Option.getOr(Js.Dict.empty())
      ->Js.Dict.get(key)
      ->Option.flatMap(x => Js.Json.decodeString(x))
    }
  | None => None
  }
}

// Initialize the Hyperswitch SDK with publishable key and profile id
// Returns a promise of hyperInstance
@genType
let init = (
  ~publishableKey: string,
  ~profileId: string,
  ~customConfig: option<Js.Json.t>=?,
): promise<HyperTypes.hyperInstance> => {
  let backendUrl = getStringFromConfig(customConfig, "customBackendUrl")
  let logUrl = getStringFromConfig(customConfig, "customLogUrl")
  let params = customConfig

  // Store config globally using function parameters
  setGlobalConfig(
    ~publishableKey,
    ~profileId,
    ~customBackendUrl=?backendUrl,
    ~customLogUrl=?logUrl,
    ~customParams=?params,
  )

  // Return a promise of hyperInstance (actual initialization happens in HyperElements)
  Promise.resolve(createHyperInstance())
}

// PaymentSession type for headless payment methods
@genType
type paymentSession = {
  getCustomerSavedPaymentMethods: unit => promise<Js.Json.t>,
  getCustomerDefaultSavedPaymentMethodData: unit => promise<Js.Json.t>,
  getCustomerLastUsedPaymentMethodData: unit => promise<Js.Json.t>,
  confirmWithCustomerDefaultPaymentMethod: unit => promise<Js.Json.t>,
  confirmWithCustomerLastUsedPaymentMethod: unit => promise<Js.Json.t>,
}

// Initialize payment session and return session object with headless methods
@genType
let initPaymentSession = (
  ~hyperPromise: promise<HyperTypes.hyperInstance>,
  ~paymentIntentClientSecret: string,
): promise<paymentSession> => {
  hyperPromise->Promise.then(_hyperInstance => {
    nativeHyperswitchSdk.initPaymentSession(~paymentIntentClientSecret)
    ->Promise.then(_initResult => {
      // Return payment session object with headless methods
      Promise.resolve({
        getCustomerSavedPaymentMethods: () => {
          nativeHyperswitchSdk.getCustomerSavedPaymentMethods()
          ->Promise.thenResolve(parsePaymentResult)
        },
        getCustomerDefaultSavedPaymentMethodData: () => {
          nativeHyperswitchSdk.getCustomerDefaultSavedPaymentMethodData()
          ->Promise.thenResolve(parsePaymentResult)
        },
        getCustomerLastUsedPaymentMethodData: () => {
          nativeHyperswitchSdk.getCustomerLastUsedPaymentMethodData()
          ->Promise.thenResolve(parsePaymentResult)
        },
        confirmWithCustomerDefaultPaymentMethod: () => {
          nativeHyperswitchSdk.confirmWithCustomerDefaultPaymentMethod()
          ->Promise.thenResolve(parsePaymentResult)
        },
        confirmWithCustomerLastUsedPaymentMethod: () => {
          nativeHyperswitchSdk.confirmWithCustomerLastUsedPaymentMethod()
          ->Promise.thenResolve(parsePaymentResult)
        },
      })
    })
  })
}

