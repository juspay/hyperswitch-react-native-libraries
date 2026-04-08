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
  globalConfigRef :=
    Some({
      publishableKey,
      profileId,
      ?customBackendUrl,
      ?customLogUrl,
      ?customParams,
    })
}

// Create a hyper instance with the given config
let createHyperInstance = (): HyperTypes.hyperInstance => {
  // confirmPayment: (paymentParams: Js.Json.t) => {}
  initPaymentSession: (sessionParams: string) => {
    nativeHyperswitchSdk.initPaymentSession(
      ~paymentIntentClientSecret=sessionParams,
    )->Promise.thenResolve(parseNativeResponse)
  },

  // completeUpdateIntent: (clientSecret: string) => {}
}

// Helper to get string from JSON config
let getStringFromConfig = (config: option<Js.Json.t>, key: string): option<string> => {
  switch config {
  | Some(cfg) =>
    cfg
    ->JSON.Decode.object
    ->Option.getOr(Dict.make())
    ->Dict.get(key)
    ->Option.flatMap(x => x->JSON.Decode.string)
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

// Helper to extract string field from JSON data
let getStringFromJsonData = (data: option<Js.Json.t>, key: string): option<string> => {
  data
  ->Option.flatMap(JSON.Decode.object)
  ->Option.flatMap(dict => dict->Dict.get(key))
  ->Option.flatMap(JSON.Decode.string)
}

// Helper to extract payment data and call confirmPaymentCVC
let confirmWithStoredPaymentMethod = (
  reactTag: int,
  storedResponse: option<HyperTypes.nativeResponse>,
  errorContext: string,
): promise<HyperTypes.nativeResponse> => {
  switch storedResponse {
  | Some(response) =>
    switch response.status {
    | Succeeded =>
      switch (getStringFromJsonData(response.data, "payment_token"), getStringFromJsonData(response.data, "payment_method_id")) {
      | (Some(paymentToken), Some(paymentMethodId)) =>
        Promise.make((resolve, _reject) => {
          NativeHyperswitchSdk.confirmPaymentCVC(reactTag, paymentToken, paymentMethodId, result => {
            resolve(parseNativeResponse(result))
          })
        })
      | _ =>
        Promise.resolve(
          parseNativeResponse(
            `{"status":"failed","code":"NO_PAYMENT_DATA","message":"Payment token or method ID not found"}`,
          ),
        )
      }
    | _ =>
      Promise.resolve(
        parseNativeResponse(`{"status":"failed","code":"NO_PAYMENT_METHOD","message":"${errorContext} request did not succeed"}`),
      )
    }
  | None =>
    Promise.resolve(
      parseNativeResponse(
        `{"status":"failed","code":"NO_PAYMENT_METHOD","message":"No ${errorContext} found. Please call getter first"}`,
      ),
    )
  }
}

// Initialize payment session
@genType
let initPaymentSession = (
  ~hyperPromise: promise<HyperTypes.hyperInstance>,
  ~paymentIntentClientSecret: string,
): promise<HyperTypes.paymentSession> => {
  hyperPromise->Promise.then(_hyperInstance => {
    nativeHyperswitchSdk.initPaymentSession(
      ~paymentIntentClientSecret,
    )->Promise.then(_initResult => {
      nativeHyperswitchSdk.getCustomerSavedPaymentMethods()->Promise.then(
        _savedMethodsResult => {
          // Create refs to store payment method data
          let defaultPaymentMethodDataRef = ref(None)
          let lastUsedPaymentMethodDataRef = ref(None)

          Promise.resolve(
            (
              {
                getCustomerDefaultSavedPaymentMethodData: () => {
                  nativeHyperswitchSdk.getCustomerDefaultSavedPaymentMethodData()->Promise.then(response => {
                    let parsedResponse = parseNativeResponse(response)
                    // Store the parsed response in ref for later use
                    defaultPaymentMethodDataRef := Some(parsedResponse)
                    Promise.resolve(parsedResponse)
                  })
                },
                getCustomerLastUsedPaymentMethodData: () => {
                  nativeHyperswitchSdk.getCustomerLastUsedPaymentMethodData()->Promise.then(response => {
                    let parsedResponse = parseNativeResponse(response)
                    // Store the parsed response in ref for later use
                    lastUsedPaymentMethodDataRef := Some(parsedResponse)
                    Promise.resolve(parsedResponse)
                  })
                },
                confirmWithCustomerDefaultPaymentMethod: widgetId => {
                  switch WidgetRegistry.getWidget(widgetId) {
                  | Some(reactTag) =>
                    if ReactNative.Platform.os == #android {
                      nativeHyperswitchSdk.confirmWithCustomerDefaultPaymentMethod(
                        reactTag,
                      )->Promise.thenResolve(parseNativeResponse)
                    } else {
                      confirmWithStoredPaymentMethod(
                        reactTag,
                        defaultPaymentMethodDataRef.contents,
                        "default payment method",
                      )
                    }
                  | None =>
                    Promise.resolve(
                      parseNativeResponse(
                        `{"status":"failed","code":"NO_WIDGET","message":"CvcWidget '${widgetId}' not found or not mounted"}`,
                      ),
                    )
                  }
                },
                confirmWithCustomerLastUsedPaymentMethod: widgetId => {
                  switch WidgetRegistry.getWidget(widgetId) {
                  | Some(reactTag) =>
                    if ReactNative.Platform.os == #android {
                      nativeHyperswitchSdk.confirmWithCustomerLastUsedPaymentMethod(
                        reactTag,
                      )->Promise.thenResolve(parseNativeResponse)
                    } else {
                      confirmWithStoredPaymentMethod(
                        reactTag,
                        lastUsedPaymentMethodDataRef.contents,
                        "last used payment method",
                      )
                    }
                  | None =>
                    Promise.resolve(
                      parseNativeResponse(
                        `{"status":"failed","code":"NO_WIDGET","message":"CvcWidget '${widgetId}' not found or not mounted"}`,
                      ),
                    )
                  }
                },
                confirmWithCustomerPaymentToken: token => {
                  nativeHyperswitchSdk.confirmWithCustomerPaymentToken(token)->Promise.thenResolve(
                    parseNativeResponse,
                  )
                },


              }: HyperTypes.paymentSession
            ),
          )
        },
      )
    })
  })
}
