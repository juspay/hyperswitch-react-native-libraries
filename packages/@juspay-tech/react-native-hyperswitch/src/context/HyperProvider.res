@genType
type customConfig = {
  customBackendUrl?: string,
  customLogUrl?: string,
  customParams?: JSON.t,
}

@genType
type hyperProviderOptions = {
  publishableKey: string,
  profileId: string,
  customConfig?: customConfig,
}

type widgetState = {
  confirmPayment: unit => unit,
  goBack: unit => unit,
  showWidget: unit => unit,
  isConfirmDisabled: bool,
  isLoading: bool,
  isReady: bool,
}

let widgetRegistry: ref<Dict.t<widgetState>> = ref(Js.Dict.empty())

let registerWidget = (id: string, controller: widgetState) => {
  Dict.set(widgetRegistry.contents, id, controller)
}

let unregisterWidget = (id: string) => {
  Dict.delete(widgetRegistry.contents, id)
}

let getWidgetState = (id: string): option<widgetState> => {
  Js.Dict.get(widgetRegistry.contents, id)
}

type hyperProviderData = {
  options: hyperProviderOptions,
  isInitialized: bool,
  error?: string,
}

let defaultVal: hyperProviderData = {
  options: {
    publishableKey: "",
    profileId: "",
  },
  isInitialized: false,
}

let hyperProviderContext = React.createContext((defaultVal, (_: hyperProviderData) => ()))

module Provider = {
  let make = React.Context.provider(hyperProviderContext)
}

@genType
let initHyperswitch = (~publishableKey, ~customBackendUrl=?, ~customLogUrl=?, ~customParams=?) => {
  NativeHyperswitchSdk.nativeHyperswitchSdk.initialise(
    ~publishableKey,
    ~customBackendUrl?,
    ~customLogUrl?,
    ~customParams?,
  )
}

@genType @react.component
let make = (~children: React.element, ~options: hyperProviderOptions) => {
  let publishableKey = options.publishableKey
  let _profileId = options.profileId
  let customConfig = options.customConfig

  let customBackendUrl = switch customConfig {
  | Some(config) => config.customBackendUrl
  | None => None
  }
  let customLogUrl = switch customConfig {
  | Some(config) => config.customLogUrl
  | None => None
  }
  let customParams = switch customConfig {
  | Some(config) => config.customParams
  | None => None
  }

  let (state, setState) = React.useState(_ => {
    options,
    isInitialized: false,
  })

  let getError = (~error="Failed to initialize Hyperswitch") => {...state, error}

  let initialise = async () => {
    try {
      let _ = await initHyperswitch(
        ~publishableKey,
        ~customBackendUrl?,
        ~customLogUrl?,
        ~customParams?,
      )
      setState(_ => {
        ...state,
        isInitialized: true,
      })
    } catch {
    | Exn.Error(obj) =>
      switch Exn.message(obj) {
      | Some(error) => setState(_ => getError(~error))
      | None => setState(_ => getError())
      }
    | _ => setState(_ => getError())
    }
  }

  React.useEffect1(() => {
    if publishableKey != "" {
      initialise()->ignore
    }
    None
  }, [publishableKey])

  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])

  <Provider value=(state, setState)> children </Provider>
}
