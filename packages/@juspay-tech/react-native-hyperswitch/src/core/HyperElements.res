// HyperElements.res
// Context provider component that handles SDK initialization
// Accepts hyper promise from Hyper.init() and options (sdkAuthorization)

open NativeHyperswitchSdk

// Options type for HyperElements
@genType
type hyperElementsOptions = {
  sdkAuthorization?: string,
}

// Use hyperInstance type from Hyper module
@genType
type hyperElementsData = {
  hyperInstance: option<HyperTypes.hyperInstance>,
  paymentSession: option<HyperTypes.paymentSession>,
  isInitialized: bool,
  error?: string,
  sdkAuthorization?: string,
}

// Default values
let defaultVal: hyperElementsData = {
  hyperInstance: None,
  paymentSession: None,
  isInitialized: false,
}

// Create context
let hyperElementsContext = React.createContext((defaultVal, (_: hyperElementsData) => ()))

module Provider = {
  let make = React.Context.provider(hyperElementsContext)
}

// Get error data helper
let getErrorData = (
  ~error="Failed to initialize Hyperswitch",
  ~sdkAuthorization="",
): hyperElementsData => {
  hyperInstance: None,
  paymentSession: None,
  isInitialized: false,
  error,
  sdkAuthorization,
}

// Initialize the native SDK
let initializeNativeSdk = async (
  ~publishableKey: string,
  ~customBackendUrl: option<string>,
  ~customLogUrl: option<string>,
  ~customParams: option<Js.Json.t>,
) => {
  await NativeHyperswitchSdk.nativeHyperswitchSdk.initialise(
    ~publishableKey,
    ~customBackendUrl,
    ~customLogUrl,
    ~customParams,
  )
}

@genType @react.component
let make = (
  ~children: React.element,
  ~hyper: promise<HyperTypes.hyperInstance>,
  ~options: option<hyperElementsOptions>=?,
) => {
  let (state, setState) = React.useState(_ => defaultVal)

  // Extract sdkAuthorization from options
  let sdkAuthorization = switch options {
  | Some(opts) => opts.sdkAuthorization->Option.getOr("")
  | None => ""
  }

  // Initialize the SDK and payment session when hyper promise resolves or options change
  React.useEffect2(() => {
    let initialize = async () => {
      try {
        let hyperInstance = await hyper

        let globalConfig = Hyper.getGlobalConfig()

        switch globalConfig {
        | Some(config) => {
            let _ = await initializeNativeSdk(
              ~publishableKey=config.publishableKey,
              ~customBackendUrl=config.customBackendUrl,
              ~customLogUrl=config.customLogUrl,
              ~customParams=config.customParams,
            )

            let paymentSession = if sdkAuthorization != "" {
              Some(await Hyper.initPaymentSession(~hyperPromise=hyper, ~sdkAuthorization))
            } else {
              None
            }
            // Initialize payment session once

            setState(_ => {
              hyperInstance: Some(hyperInstance),
              paymentSession: paymentSession,
              isInitialized: true,
              sdkAuthorization,
            })
          }
        | None =>
          setState(_ =>
            getErrorData(
              ~error="Hyper config not found. Call Hyper.init() before rendering HyperElements.",
              ~sdkAuthorization,
            )
          )
        }
      } catch {
      | Exn.Error(obj) =>
        switch Exn.message(obj) {
        | Some(error) => setState(_ => getErrorData(~error))
        | None => setState(_ => getErrorData())
        }
      | _ => setState(_ => getErrorData())
      }
    }

    initialize()->ignore
    None
  }, (hyper, sdkAuthorization))

  let setState = React.useCallback1((val: hyperElementsData) => {
    setState(_ => val)
  }, [])

  <Provider value=(state, setState)> children </Provider>
}

// Hook to use HyperElements context
let useHyperElements = () => {
  React.useContext(hyperElementsContext)
}
