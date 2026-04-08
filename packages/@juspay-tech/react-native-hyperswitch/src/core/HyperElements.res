// HyperElements.res
// Context provider component that handles SDK initialization
// Accepts hyper promise from Hyper.init() and options (sdkAuthorization)

open NativeHyperswitchSdk

// Options type for HyperElements
@genType
type hyperElementsOptions = {
  clientSecret: option<string>,
  sdkAuthorization: option<string>,
}

// Use hyperInstance type from Hyper module
@genType
type hyperElementsData = {
  hyperInstance: option<HyperTypes.hyperInstance>,
  paymentSession: option<HyperTypes.paymentSession>,
  isInitialized: bool,
  error?: string,
  clientSecret: option<string>,
  sdkAuthorization: option<string>,
}

// Default values
let defaultVal: hyperElementsData = {
  hyperInstance: None,
  paymentSession: None,
  isInitialized: false,
  clientSecret: None,
  sdkAuthorization: None,
}

// Create context
let hyperElementsContext = React.createContext((defaultVal, (_: hyperElementsData) => ()))

module Provider = {
  let make = React.Context.provider(hyperElementsContext)
}

// Get error data helper
let getErrorData = (
  ~error="Failed to initialize Hyperswitch",
  ~clientSecret=None,
  ~sdkAuthorization=None,
): hyperElementsData => {
  hyperInstance: None,
  paymentSession: None,
  isInitialized: false,
  error,
  clientSecret,
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

  // Extract sdkAuthorization and clientSecret from options
  let sdkAuthorization = switch options {
  | Some(opts) => opts.sdkAuthorization
  | None => None
  }

  let clientSecret = switch options {
  | Some(opts) => opts.clientSecret
  | None => None
  }

  // Initialize the SDK and payment session when hyper promise resolves or options change
  React.useEffect3(() => {
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

            // Initialize payment session once
            let paymentSession = await Hyper.initPaymentSession(
              ~hyperPromise=hyper,
              ~paymentIntentClientSecret=clientSecret->Option.getOr(""),
            )

            setState(_ => {
              hyperInstance: Some(hyperInstance),
              paymentSession: Some(paymentSession),
              isInitialized: true,
              clientSecret,
              sdkAuthorization,
            })
          }
        | None =>
          setState(_ =>
            getErrorData(
              ~error="Hyper config not found. Call Hyper.init() before rendering HyperElements.",
              ~clientSecret,
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
  }, (hyper, clientSecret, sdkAuthorization))

  let setState = React.useCallback1((val: hyperElementsData) => {
    setState(_ => val)
  }, [])

  <Provider value=(state, setState)> children </Provider>
}

// Hook to use HyperElements context
let useHyperElements = () => {
  React.useContext(hyperElementsContext)
}
