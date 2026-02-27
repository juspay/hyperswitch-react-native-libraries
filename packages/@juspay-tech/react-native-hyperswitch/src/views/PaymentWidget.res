

@module("ReactNative") @scope("UIManager")
external dispatchViewManagerCommand: (
  ~viewId: int,
  ~commandId: int,
  ~commandArgs: array<string>,
) => unit = "dispatchViewManagerCommand"

@react.component @genType
let make = (
  ~widgetId,
  ~widgetType,
  ~onPaymentResult,
  ~options: option<PaymentSheetConfiguration.options>,
  ~clientSecret: option<string>,
) => {
  let ref = React.useRef(None)

  React.useEffect(() => {
    if (ref.current->Option.isSome) {
        // ReactNative.UIManager.dispatchViewManagerCommand
        dispatchViewManagerCommand(
          ~viewId=10,
          ~commandId=0, // commandId, can be used to identify the command in native code
          ~commandArgs=[] // commandArgs, can be used to pass additional data to native code
        )
      ()
    }
    None
  }, [widgetId, widgetType, onPaymentResult, options])

  <NativePaymentWidget
    // ref={ref}
    // widgetId={widgetId}
    clientSecret={clientSecret->Option.getOr("")}
    // widgetType={widgetType}
    // onPaymentResult={onPaymentResult}
    options={switch options {
    | Some(opts) => JSON.stringifyAny(opts)
    | None => None
    }->Option.getOr("")}
  />
}
