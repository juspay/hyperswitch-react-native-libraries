open HyperTypes

@genType
type hyperElementsContext = {
  isSessionInitialized: bool,
  sdkAuthorisation?: string,
  clientSecret?: string,
}

let defaultContext: hyperElementsContext = {
  isSessionInitialized: false,
}

let hyperElementsContext = React.createContext(defaultContext)

module Provider = {
  let make = React.Context.provider(hyperElementsContext)
}

@genType @react.component
let make = (
  ~children: React.element,
  ~options: hyperElementsOptions,
) => {
  // Get HyperProvider context to check initialization
  let (providerData, _) = React.useContext(HyperProvider.hyperProviderContext)

  // Extract session configuration
  let sdkAuthorisation = options.sdkAuthorisation
  let clientSecret = options.clientSecret

  // State for session initialization
  let (sessionState, setSessionState) = React.useState(() => {
    isSessionInitialized: false,
    ?sdkAuthorisation,
    ?clientSecret,
  })

  // Initialize payment session
  let initialiseSession = async () => {
    let authValue = switch sdkAuthorisation {
    | Some(auth) => auth
    | None =>
      switch clientSecret {
      | Some(secret) => secret
      | None => ""
      }
    }

    if (authValue != "") {
      try {
        let _ = await NativeHyperswitchSdk.nativeHyperswitchSdk.initPaymentSession(
          ~paymentIntentClientSecret=authValue,
        )
        setSessionState(_ => {
          isSessionInitialized: true,
          ?sdkAuthorisation,
          ?clientSecret,
        })
      } catch {
      | _ =>
        setSessionState(_ => {
          isSessionInitialized: false,
          ?sdkAuthorisation,
          ?clientSecret,
        })
      }
    }
  }

  React.useEffect1(() => {
    if providerData.isInitialized {
      initialiseSession()->ignore
    }
    None
  }, [providerData.isInitialized])

  <Provider value={sessionState}>
    children
  </Provider>
}

let useHyperElements = () => {
  React.useContext(hyperElementsContext)
}
