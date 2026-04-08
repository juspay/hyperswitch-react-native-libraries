// useWidget.res
// Hook for accessing widget methods within HyperElements context

type useWidget = {
  isReady: bool,
  confirmPayment: string => promise<NativeHyperswitchSdk.paymentResult>,
}

// Hook to access widget methods and state
@genType
let useWidget = () => {
  let (contextData, _) = HyperElements.useHyperElements()
  let (isReady, setIsReady) = React.useState(_ => false)

  let isInitialized = contextData.isInitialized && contextData.error->Option.isNone
  let _hyperInstance = contextData.hyperInstance

  React.useEffect1(() => {
    setIsReady(_ => isInitialized)
    None
  }, [isInitialized])

  let confirmPayment = React.useCallback0((widgetId: string) => {
    WidgetRegistry.confirmPayment(widgetId)
  })

  {
    isReady,
    confirmPayment,
  }
}