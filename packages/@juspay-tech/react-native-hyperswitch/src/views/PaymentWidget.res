@module("react-native") @scope("UIManager")
external dispatchViewManagerCommand: (
  ~viewId: int,
  ~commandId: int,
  ~commandArgs: array<int>,
) => unit = "dispatchViewManagerCommand"

@module("react-native")
external findNodeHandle: Js.Nullable.t<unit> => int = "findNodeHandle"

@scope("JSON") @val external parse: string => NativeModuleTypes.paymentResult = "parse"

type commands = {createView: string}

type viewManagerConfig = {"Commands": commands}

// Event types for widget state
type widgetEvent = {
  eventName: string,
  payload: option<Js.Json.t>,
}

let createView = viewId => {
  dispatchViewManagerCommand(~viewId, ~commandId=1, ~commandArgs=[])
}

@react.component @genType
let make = (
  ~widgetId,
  ~onPaymentResult,
  ~options: option<PaymentSheetConfiguration.options>=?,
  ~style: option<ReactNative.Style.t>=?,
) => {
  let (viewId, setViewId) = React.useState(_ => None)
  let viewRef: React.ref<Nullable.t<unit>> = React.useRef(Nullable.null)
  let (isReady, setIsReady) = React.useState(_ => false)
  let (isConfirmDisabled, setIsConfirmDisabled) = React.useState(_ => true)
  let (isLoading, setIsLoading) = React.useState(_ => false)

  // Register widget with HyperProvider
  React.useEffect4(() => {
    let controller : HyperProvider.widgetState = {
      confirmPayment: () => {
        // This will be called by useHyperWidget hook
        ()
      },
      goBack: () => {
        // Handle goBack - can be emitted to native or bundle
        ()
      },
      isConfirmDisabled: isConfirmDisabled,
      isLoading: isLoading,
      isReady: isReady,
    }

    HyperProvider.registerWidgetSetter(widgetId, (controller)=>())

    Some(() => {
      HyperProvider.unregisterWidgetSetter(widgetId)
    })
  }, (widgetId, isReady, isConfirmDisabled, isLoading))

  // run after mount
  React.useEffect(() => {
    switch Js.Nullable.toOption(viewRef.current) {
    | Some(_) =>
      setViewId(_ => Some(findNodeHandle(viewRef.current)))
      ()
    | None => ()
    }
    None
  }, [])

  React.useEffect(() => {
    switch viewId {
    | Some(id) => createView(id)
    | None => ()
    }
    None
  }, [viewId])

  let onPaymentResultInternal = (event: NativeModuleTypes.nativeEvent) => {
    onPaymentResult(event.nativeEvent.result->Option.getOr("")->parse)
  }

  <NativePaymentWidget
    ref={viewRef}
    widgetId={widgetId}
    widgetType={"widgetPaymentSheet"}
    clientSecret=?{switch options {
      | Some(options) => options.clientSecret
      | None => None
    }}
    onPaymentResult={onPaymentResultInternal}
    options=?options
    style=?style
  />
}
