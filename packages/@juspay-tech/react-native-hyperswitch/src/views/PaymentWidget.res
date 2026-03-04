@module("react-native") @scope("UIManager")
external dispatchViewManagerCommand: (
  ~viewId: int,
  ~commandId: int,
  ~commandArgs: array<int>,
) => unit = "dispatchViewManagerCommand"

@module("react-native")
external findNodeHandle: Js.Nullable.t<unit> => int = "findNodeHandle"

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
  ~widgetType,
  ~onPaymentResult,
  ~options,
  ~style,
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
    onPaymentResult(event.nativeEvent)
  }

  <NativePaymentWidget
    ref={viewRef}
    widgetId={widgetId}
    widgetType={widgetType}
    onPaymentResult={onPaymentResultInternal}
    options={switch options {
    | Some(opts) => JSON.stringifyAny(opts)->Option.getOr("")
    | None => ""
    }}
    style={style}
  />
}
