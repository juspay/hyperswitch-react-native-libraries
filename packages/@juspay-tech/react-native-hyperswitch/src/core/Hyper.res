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
          Promise.resolve(
            (
              {
                getCustomerDefaultSavedPaymentMethodData: () => {
                  nativeHyperswitchSdk.getCustomerDefaultSavedPaymentMethodData()->Promise.thenResolve(
                    parseNativeResponse,
                  )
                },
                getCustomerLastUsedPaymentMethodData: () => {
                  nativeHyperswitchSdk.getCustomerLastUsedPaymentMethodData()->Promise.thenResolve(
                    parseNativeResponse,
                  )
                },
                confirmWithCustomerDefaultPaymentMethod: widgetId => {
                  switch WidgetRegistry.getWidget(widgetId) {
                  | Some(reactTag) =>
                    nativeHyperswitchSdk.confirmWithCustomerDefaultPaymentMethod(
                      reactTag,
                    )->Promise.thenResolve(parseNativeResponse)
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
                    nativeHyperswitchSdk.confirmWithCustomerLastUsedPaymentMethod(
                      reactTag,
                    )->Promise.thenResolve(parseNativeResponse)
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
