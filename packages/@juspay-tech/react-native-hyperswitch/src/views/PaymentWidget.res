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
  ReactNativeUtils.dispatchViewManagerCommand(~viewId, ~commandId=1, ~commandArgs=[])
}

type paymentWidgetRef = {confirmPayment: unit => promise<HyperTypes.nativeResponse>}

type pendingConfirmation = {
  resolve: HyperTypes.nativeResponse => unit,
  reject: exn => unit,
}

@react.component @genType
let make = React.forwardRef((
  ~widgetId: string,
  ~onPaymentResult: NativeModuleTypes.paymentResult => unit,
  ~options: option<PaymentSheetConfiguration.options>=?,
  ~style: option<ReactNative.Style.t>=?,
  ref,
) => {
  let (viewId, setViewId) = React.useState(_ => None)
  let viewRef: React.ref<Nullable.t<unit>> = React.useRef(Nullable.null)
  let (hyperElementsContext, _) = HyperElements.useHyperElements()
  let pendingConfirmationRef: React.ref<option<pendingConfirmation>> = React.useRef(None)

  React.useEffect(() => {
    switch Js.Nullable.toOption(viewRef.current) {
    | Some(_) =>
      setViewId(_ => Some(findNodeHandle(viewRef.current)))
      ()
    | None => ()
    }
    None
  }, [])

  let onConfirmationResult = (event: NativeModuleTypes.nativeEvent) => {
    let result = event.nativeEvent.result
    let parsedResult = result->Option.getOr("")->parse
    switch pendingConfirmationRef.current {
    | Some({resolve}) => {
        pendingConfirmationRef.current = None
        let response: HyperTypes.nativeResponse = {
          status: switch parsedResult.status->Option.getOr("") {
          | "succeeded" => HyperTypes.Succeeded
          | "failed" => HyperTypes.Failed
          | "cancelled" => HyperTypes.Cancelled
          | _ => HyperTypes.Error
          },
          message: parsedResult.errorMessage->Option.getOr("Payment completed"),
        }
        resolve(response)
      }
    | None => onPaymentResult(parsedResult)
    }
  }

  React.useImperativeHandle(
    ref,
    () => {
      {
        confirmPayment: (): promise<HyperTypes.nativeResponse> => {
          switch Js.Nullable.toOption(viewRef.current) {
          | Some(_) =>
            switch Some(findNodeHandle(viewRef.current)) {
            | Some(id) => {
                let promise = Promise.make((resolve, reject) => {
                  pendingConfirmationRef.current = Some({resolve, reject})
                })
                ReactNativeUtils.dispatchViewManagerCommand(
                  ~viewId=id,
                  ~commandId=2,
                  ~commandArgs=[],
                )
                promise
              }
            | None => {
                let response: HyperTypes.nativeResponse = {
                  status: HyperTypes.Failed,
                  message: "Widget not ready",
                }
                Promise.resolve(response)
              }
            }
          | None => {
              let response: HyperTypes.nativeResponse = {
                status: HyperTypes.Failed,
                message: "Widget not ready",
              }
              Promise.resolve(response)
            }
          }
        },
      }
    },
    [viewId],
  )

  React.useEffect(() => {
    switch viewId {
    | Some(id) => {
        WidgetRegistry.registerWidget(widgetId, id)
        createView(id)
      }
    | None => ()
    }
    None
  }, [viewId])

  let onPaymentResultInternal = (event: NativeModuleTypes.nativeEvent) => {
    onPaymentResult(event.nativeEvent.result->Option.getOr("")->parse)
  }

  // Only render if HyperElements is initialized
  if !hyperElementsContext.isInitialized {
    React.null
  } else {
    switch hyperElementsContext.clientSecret {
    | Some(clientSecret) =>
      <NativePaymentWidget
        ref={viewRef}
        widgetId={widgetId}
        widgetType={"widgetPaymentSheet"}
        clientSecret={clientSecret}
        onConfirmationResult={onConfirmationResult}
        onPaymentResult={onPaymentResultInternal}
        ?options
        ?style
      />
    | None => React.null
    }
  }
})
