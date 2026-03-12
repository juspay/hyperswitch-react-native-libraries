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

type viewManagerConfig = {\"Commands": commands}

// @module("react-native") @scope("UIManager")
// external getViewManagerConfig: string => viewManagerConfig = "getViewManagerConfig"
// @send external commands: Js.t<{..}> => Js.t<{..}> = "Commands"
// @send external createViewCmd: Js.t<{..}> => string = "createView"

// @val external toString: 't => string = "toString"

// let getCreateViewCommand = () => {
//   getViewManagerConfig("NativePaymentWidget").\"Commands".createView->toString
//   }

let createView = viewId => {
  dispatchViewManagerCommand(~viewId, ~commandId=1, ~commandArgs=[])
}

@react.component @genType
let make = (
  ~widgetId,
  ~onPaymentResult,
  ~onPaymentEvent: option<NativeModuleTypes.paymentEventResult => unit>=?,
  ~options: option<PaymentSheetConfiguration.options>=?,
  ~style: option<ReactNative.Style.t>=?,
) => {
  let (viewId, setViewId) = React.useState(_ => None)
  let viewRef: React.ref<Nullable.t<unit>> = React.useRef(Nullable.null)
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

  let onPaymentEventInternal = (event: NativeModuleTypes.paymentEventNative) => {
    switch onPaymentEvent {
    | Some(callback) => callback(event.nativeEvent)
    | None => ()
    }
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
    onPaymentEvent={onPaymentEventInternal}
    ?options
    ?style
  />
}
