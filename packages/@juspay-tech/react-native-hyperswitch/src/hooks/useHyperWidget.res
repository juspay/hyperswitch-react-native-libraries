open NativeHyperswitchSdk

@genType
type useHyperWidgetReturnType = {
  goBack: unit => unit,
  confirmPayment: unit => promise<presentPaymentSheetResult>,
  isReady: bool,
  isConfirmDisabled: bool,
  isLoading: bool,
}

type widgetState = {
  isReady: bool,
  isLoading: bool,
  isConfirmDisabled: bool,
}

@genType
let useHyperWidget = (widgetId: string): useHyperWidgetReturnType => {
  let (widgetState, _) = React.useState(() => 
    ({
      isReady: false,
      isLoading: false,
      isConfirmDisabled: true,
    })
  )
  let goBack = React.useCallback1(() => {
    nativeHyperswitchSdk.goBack(widgetId)
  }, [widgetId])

  let confirmPayment = React.useCallback1(() => {
    nativeHyperswitchSdk.confirmPayment(widgetId)
  }, [widgetId])

  {
    goBack,
    confirmPayment,
    isReady : widgetState.isReady,
    isConfirmDisabled: widgetState.isConfirmDisabled,
    isLoading: widgetState.isLoading,
  }
}
