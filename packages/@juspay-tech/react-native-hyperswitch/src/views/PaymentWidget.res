@module("react-native") @scope("UIManager")
external dispatchViewManagerCommand: (
  ~viewId: int,
  ~commandId: int,
  ~commandArgs: array<int>,
) => unit = "dispatchViewManagerCommand"

open ReactNative
open Style

@module("react-native")
external findNodeHandle: Js.Nullable.t<unit> => int = "findNodeHandle"

type commands = {
  createView: string,
}

type viewManagerConfig = {
  \"Commands": commands,
}

@module("react-native") @scope("UIManager")
external getViewManagerConfig: string => viewManagerConfig = "getViewManagerConfig"
@send external commands: Js.t<{..}> => Js.t<{..}> = "Commands"
@send external createViewCmd: Js.t<{..}> => string = "createView"

@val external toString: 't => string = "toString"

// let getCreateViewCommand = () => {
//   getViewManagerConfig("NativePaymentWidget").\"Commands".createView->toString
//   }


let createView = viewId => {
  dispatchViewManagerCommand(
    ~viewId,
    ~commandId=1,
    ~commandArgs=[viewId],
  )
}


@react.component @genType
let make = (
  ~widgetId,
  ~widgetType,
  ~onPaymentResult,
  ~options: option<PaymentSheetConfiguration.options>,
  ~clientSecret: option<string>,
) => {
    let viewRef: React.ref<Js.Nullable.t<unit>> =
    React.useRef(Js.Nullable.null)
  // run after mount
  React.useEffect(() => {
    switch Js.Nullable.toOption(viewRef.current) {
    | Some(_) =>
        let viewId = findNodeHandle(viewRef.current)
        createView(viewId)
        None
    | None => None
    }
  }, [])

  <NativePaymentWidget
    ref={viewRef}
    widgetId={widgetId}
    widgetType={widgetType}
    clientSecret={clientSecret->Option.getOr("")}
    onPaymentResult={onPaymentResult}
    options={switch options {
    | Some(opts) => JSON.stringifyAny(opts)
    | None => None
    }->Option.getOr("")}
    style={{
      flex: 1.
    }}
  />
}
