// HyperElements.res
// Context provider component that handles SDK initialization
// Accepts hyper promise from Hyper.init() and options (sdkAuthorisationForPayments)

open NativeHyperswitchSdk

// Options type for HyperElements
@genType
type hyperElementsOptions = {
  clientSecret: option<string>,
  sdkAuthorisation: option<string>,
}

// Use hyperInstance type from Hyper module
type hyperElementsData = {
  hyperInstance: option<HyperTypes.hyperInstance>,
  isInitialized: bool,
  error?: string,
  clientSecret: option<string>,
  sdkAuthorisation: option<string>,
}

// Widget registry for managing widget states
let widgetRegistry: ref<Dict.t<HyperTypes.widgetController>> = ref(Js.Dict.empty())

let registerWidget = (id: string, controller: HyperTypes.widgetController) => {
  Dict.set(widgetRegistry.contents, id, controller)
}

let unregisterWidget = (id: string) => {
  Dict.delete(widgetRegistry.contents, id)
}

let getWidgetState = (id: string): option<HyperTypes.widgetController> => {
  Dict.get(widgetRegistry.contents, id)
}

// Default values
let defaultVal: hyperElementsData = {
  hyperInstance: None,
  isInitialized: false,
  clientSecret: None,
  sdkAuthorisation: None,
}

// Create context
let hyperElementsContext = React.createContext((defaultVal, (_: hyperElementsData) => ()))

module Provider = {
  let make = React.Context.provider(hyperElementsContext)
}

// Get error data helper
let getErrorData = (~error="Failed to initialize Hyperswitch", ~clientSecret=None, ~sdkAuthorisation=None): hyperElementsData => {
  hyperInstance: None,
  isInitialized: false,
  error: error,
  clientSecret: clientSecret,
  sdkAuthorisation: sdkAuthorisation,
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

  // Extract sdkAuthorisation and clientSecret from options
  let sdkAuthorisation = switch options {
  | Some(opts) => opts.sdkAuthorisation
  | None => None
  }

  let clientSecret = switch options {
  | Some(opts) => opts.clientSecret
  | None => None
  }

  // Initialize the SDK when hyper promise resolves or options change
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

            setState(_ => {
              hyperInstance: Some(hyperInstance),
              isInitialized: true,
              clientSecret: clientSecret,
              sdkAuthorisation: sdkAuthorisation,
            })
          }
        | None => {
            setState(_ => getErrorData(
              ~error="Hyper config not found. Call Hyper.init() before rendering HyperElements.",
              ~clientSecret=clientSecret,
              ~sdkAuthorisation=sdkAuthorisation,
            ))
          }
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
  }, (hyper, clientSecret, sdkAuthorisation))

  let setState = React.useCallback1((val: hyperElementsData) => {
    setState(_ => val)
  }, [])

  <Provider value=(state, setState)>
    children
  </Provider>
}

// Hook to use HyperElements context
@genType
let useHyperElements = () => {
  React.useContext(hyperElementsContext)
}
