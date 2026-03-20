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
  let (widgetState, setWidgetState) = React.useState(() => 
    ({
      isReady: false,
      isLoading: false,
      isConfirmDisabled: true,
    })
  )

  React.useEffect(()=>{
    NativeEventListener.setupNativeEventListener(
      "widgetStateChange",
      (response) => {
        let parsed = response->JSON.parseExn
        switch parsed->JSON.Decode.object {
        | Some(obj) =>
          let receivedWidgetId = obj->Dict.get("widgetId")->Belt.Option.flatMap(JSON.Decode.string)
          if receivedWidgetId == Some(widgetId) {
            let isReady = obj->Dict.get("isReady")->Belt.Option.flatMap(JSON.Decode.bool)->Belt.Option.getWithDefault(widgetState.isReady)
            let isLoading = obj->Dict.get("isLoading")->Belt.Option.flatMap(JSON.Decode.bool)->Belt.Option.getWithDefault(widgetState.isLoading)
            let isConfirmDisabled = obj->Dict.get("isConfirmDisabled")->Belt.Option.flatMap(JSON.Decode.bool)->Belt.Option.getWithDefault(widgetState.isConfirmDisabled)
            setWidgetState(_ => {
              isReady,
              isLoading,
              isConfirmDisabled,
            })
          }
        | None => ()
        }
      }
    )->ignore
    None
  },[widgetId])


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
