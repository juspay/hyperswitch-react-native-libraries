open NativeHyperswitchSdk
open ReactNative

@genType
type useHyperWidgetReturnType = {
  goBack: unit => unit,
  confirmPayment: unit => promise<presentPaymentSheetResult>,
  isReady: bool,
  isConfirmDisabled: bool,
  isLoading: bool,
}

// Local state type (matches HyperProvider.widgetState)
type widgetState = {
  isReady: bool,
  isLoading: bool,
  isConfirmDisabled: bool,
}

@genType
let useHyperWidget = (widgetId: string): useHyperWidgetReturnType => {
  let (contextData, _) = React.useContext(HyperProvider.hyperProviderContext)
  let isProviderReady = contextData.isInitialized && contextData.error->Belt.Option.isNone

  // Get initial state from global registry (or default)
  let initialState = HyperProvider.getWidgetState(widgetId)

  // Local React state - updated by HyperProvider when events arrive
  let (widgetState, setWidgetState) = React.useState(() => initialState)

  // Register this widget's setter with HyperProvider on mount
  React.useEffect(() => {
    HyperProvider.registerWidgetSetter(widgetId, setWidgetState)

    Some(() => {
      HyperProvider.unregisterWidgetSetter(widgetId)
    })
  }, [widgetId])

  // Combine provider ready state with widget ready state
  let isReady = isProviderReady && widgetState.isReady

  // Event handlers - simply call native SDK
  let goBack = React.useCallback1(() => {
    nativeHyperswitchSdk.goBack(widgetId)
  }, [widgetId])

  let confirmPayment = React.useCallback1(() => {
    nativeHyperswitchSdk.confirmPayment(widgetId)
  }, [widgetId])

  {
    goBack,
    confirmPayment,
    isReady,
    isConfirmDisabled: widgetState.isConfirmDisabled,
    isLoading: widgetState.isLoading,
  }
}
