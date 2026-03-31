// Hyper.res
// Main entry point for the Hyperswitch SDK
// Provides Hyper.init() function to create a hyper instance with configuration

open NativeHyperswitchSdk
open ResponseHandler

type globalConfig = {
  publishableKey: string,
  profileId: string,
  customBackendUrl?: string,
  customLogUrl?: string,
  customAssetUrl?: string,
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
  ~customAssetUrl: option<string>=?,
) => {
  globalConfigRef := Some({
    publishableKey: publishableKey,
    profileId: profileId,
    ?customBackendUrl,
    ?customLogUrl,
    ?customParams,
    ?customAssetUrl,
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
    errorObj->Dict.set("status", "error"->Js.Json.string)
    errorObj->Dict.set("code", "PARSE_ERROR"->Js.Json.string)
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
  let assetUrl = getStringFromConfig(customConfig, "customAssetUrl")
  let params = customConfig

  // Store config globally using function parameters
  setGlobalConfig(
    ~publishableKey,
    ~profileId,
    ~customBackendUrl=?backendUrl,
    ~customLogUrl=?logUrl,
    ~customParams=?params,
    ~customAssetUrl=?assetUrl,
  )

  // Return a promise of hyperInstance (actual initialization happens in HyperElements)
  Promise.resolve(createHyperInstance())
}

// Initialize payment session 
@genType
let initPaymentSession = (
  ~hyperPromise: promise<HyperTypes.hyperInstance>,
  ~paymentIntentClientSecret: string,
): promise<HyperTypes.paymentSession> => {
  hyperPromise->Promise.then(_hyperInstance => {
    nativeHyperswitchSdk.initPaymentSession(~paymentIntentClientSecret)
    ->Promise.then(_initResult => {
      nativeHyperswitchSdk.getCustomerSavedPaymentMethods()
      ->Promise.then(_savedMethodsResult => {
        Promise.resolve({
          getCustomerDefaultSavedPaymentMethodData: () => {
            nativeHyperswitchSdk.getCustomerDefaultSavedPaymentMethodData()
            ->Promise.thenResolve(parseResponse)
          },
          getCustomerLastUsedPaymentMethodData: () => {
            nativeHyperswitchSdk.getCustomerLastUsedPaymentMethodData()
            ->Promise.thenResolve(parseResponse)
          },
          confirmWithCustomerDefaultPaymentMethod: () => {
            nativeHyperswitchSdk.confirmWithCustomerDefaultPaymentMethod()
            ->Promise.thenResolve(parseResponse)
          },
          confirmWithCustomerLastUsedPaymentMethod: () => {
            nativeHyperswitchSdk.confirmWithCustomerLastUsedPaymentMethod()
            ->Promise.thenResolve(parseResponse)
          },
        }: HyperTypes.paymentSession)
      })
    })
  })
}
